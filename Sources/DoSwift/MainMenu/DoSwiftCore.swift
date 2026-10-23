//
//  DoSwiftCore.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 核心管理器。
///
/// 对外只有三个方法：`start` 一次配置并显示，`show` / `hide` 成对切换可见性。
/// 主菜单在 `start` 时一次性定妥，运行期间不再增删；window 之间互相独立，
/// 因此这里不提供任何页面栈接口——各工具自己持有并管理自己的 window。
public class DoSwiftCore {

    public static let shared = DoSwiftCore()
    private init() {}

    // MARK: - Properties

    /// 业务 App 的主 window。weak 持有——它的生命周期由业务自己管理。
    /// UI 结构类的工具以它为基准定位业务视图。
    public private(set) weak var appWindow: UIWindow?

    /// DoSwift 自己的悬浮窗，承载手柄与主菜单面板。
    public private(set) var window: OverlayWindow?

    // MARK: - Public Interface

    /// 唯一入口：传入业务 App 的 window、自定义菜单项与自定义插件，完成初始化并显示。
    ///
    /// 默认菜单写死在 `defaultGroups()`；业务传入的自定义项与插件**合并进同一个分组**，
    /// 追加在默认分组之后（先菜单项、后插件，顺序与传入一致）。运行期间不再改动——
    /// 要加工具就在下一次 `start` 时给全。
    public func start(
        appWindow: UIWindow?,
        items: [DoSwiftMenuItem] = [],
        plugins: [DoSwiftPlugin] = []
    ) {
        self.appWindow = appWindow
        
        menuGroups = []
        
        // 插件转成菜单项时会把宿主一起建好，旧的一批先丢掉，免得重复 start 时越积越多
        pluginHosts.removeAll()
        let customItems = items + plugins.map({ makeItem(for: $0) })
        if !customItems.isEmpty {
            menuGroups.append(DoSwiftMenuGroup(title: DoSwiftCore.customGroupTitle, items: customItems))
        }
        menuGroups += DoSwiftCore.defaultGroups()
        
        attachActions()

        prepare()
        window?.isHidden = false
    }

    /// 显示悬浮窗
    public func show() {
        prepare()
        window?.isHidden = false
    }

    /// 隐藏悬浮窗
    public func hide() {
        window?.isHidden = true
    }

    // MARK: - Private

    /// 业务自定义菜单项统一并入的分组标题
    private static let customGroupTitle = "自定义"

    private var menuGroups: [DoSwiftMenuGroup] = []

    /// 业务插件的宿主。core 持有，插件的页面靠它 `hide()` 自己。
    private var pluginHosts: [DoSwiftPluginHost] = []

    /// 把一个插件变成一个菜单项：行为在创建时挂成 `host.show()`。
    ///
    /// 菜单项本身仍然只有数据（见 `DoSwiftMenuItem`），且 `attachActions()` 只补没有
    /// handler 的项，所以这里挂上的行为不会被覆盖。
    private func makeItem(for plugin: DoSwiftPlugin) -> DoSwiftMenuItem {
        let host = DoSwiftPluginHost(plugin: plugin)
        pluginHosts.append(host)

        return DoSwiftMenuItem(
            identifier: plugin.identifier,
            title: plugin.title,
            icon: plugin.icon,
            actionHandler: { _ in host.show() }
        )
    }

    private func prepare() {
        guard window == nil else { return }

        // 兜底：没调过 start 就直接 show 也要能拿到默认菜单。
        // 之前 Example 从没调用过初始化、菜单一直是空的，点手柄毫无反应——
        // 那类「静默失效」不该重演。
        if menuGroups.isEmpty {
            menuGroups = DoSwiftCore.defaultGroups()
        }
        attachActions()

        // 场景由 OverlayWindow 初始化时绑定；层级取 .statusBar，
        // 否则业务 App 重建 rootViewController 后会把 .normal 的浮窗压到后面（表现为浮窗消失）。
        let overlayWindow = OverlayWindow(frame: UIScreen.main.bounds, level: .statusBar)
        overlayWindow.isHidden = true
        overlayWindow.backgroundColor = .clear

        let root = DoSwiftMainViewController()
        root.menuGroups = menuGroups
        overlayWindow.rootViewController = root

        window = overlayWindow

        // 重要：必须最后调用。它把 root.view 登记为「不响应事件」的视图，
        // 于是面板之外的触摸会穿透到底下的业务 App——非模态就是靠这个实现的。
        overlayWindow.addNoResponseView(root.view)
    }

    /// 把行为挂到对应的菜单项上。
    ///
    /// 菜单项本身**只有数据**（`actionHandler` 一律为 nil），行为集中在这里，
    /// 于是面板只需认识 `DoSwiftMenuGroup`，完全不必知道任何工具的存在。
    /// 已经有 handler 的不覆盖，业务可以先挂自己的实现。
    private func attachActions() {
        for group in menuGroups {
            for item in group.items where item.actionHandler == nil {
                if item.identifier == "app_info" {
                    item.actionHandler = { _ in AppInfoPlugin.shared.show() }
                }
                if item.identifier == "ui_hierarchy" {
                    item.actionHandler = { [weak self] _ in self?.showUIHierarchy() }
                }
                if item.identifier == "user_defaults" {
                    item.actionHandler = { _ in UserDefaultsPlugin.shared.show() }
                }
                if item.identifier == "nslog" {
                    item.actionHandler = { _ in ConsolePlugin.shared.show() }
                }
                if item.identifier == "performance" {
                    item.actionHandler = { _ in PerfTrendPlugin.shared.show() }
                }
            }
        }
    }

    /// 默认菜单：37 项 / 5 个分组。
    ///
    /// 内容镜像 DoKit-iOS 的主菜单（`DoraemonManager.m` 的 `initData` 注册顺序
    /// 配合 `getDefaultPluginDataWithPluginType:` 的标题/图标/模块表），顶层扁平、无二级。
    /// DoKit 里「Weex」与「平台工具」分别由 `DoraemonWithWeex` / `DoraemonWithDiDi`
    /// 编译开关控制，这里无条件全量镜像；要裁掉就删对应分组。
    ///
    /// 图标一律取 iOS 13（SF Symbols 1）就存在的符号，37 个逐个核对过 SF Symbols 的
    /// `name_availability.plist`（`year == 2019`）且无重复。原版用自带切图
    /// （`doraemon_fps` 这类），后续换切图只需改这里的符号名。
    private static func defaultGroups() -> [DoSwiftMenuGroup] {

        func item(_ id: String, _ title: String, _ symbol: String) -> DoSwiftMenuItem {
            return DoSwiftMenuItem(identifier: id, title: title, icon: UIImage(systemName: symbol))
        }

        let common = DoSwiftMenuGroup(title: "常用工具", items: [
            item("app_setting",    "应用设置",      "gear"),
            item("app_info",       "App信息",       "info.circle"),
            item("sandbox",        "沙盒浏览器",    "folder"),
            item("mock_gps",       "Mock GPS",      "location"),
            item("h5",             "H5任意门",      "safari"),
            item("clean_cache",    "清理缓存",      "trash"),
            item("nslog",          "NSLog",         "doc.text"),
            item("lumberjack",     "Lumberjack",    "doc.plaintext"),
            item("db_view",        "DBView",        "archivebox"),
            item("user_defaults",  "UserDefaults",  "rectangle.grid.2x2"),
            item("js_script",      "JS脚本",        "chevron.left.slash.chevron.right"),
        ])

        let performance = DoSwiftMenuGroup(title: "性能", items: [
            item("performance", "性能", "gauge"),
        ])

        let visual = DoSwiftMenuGroup(title: "视觉工具", items: [
            item("ui_hierarchy", "视图结构",   "viewfinder"),
        ])

        return [visual, performance, common]
    }
    
    private func showUIHierarchy() {
        HierarchyPlugin.shared.show()
    }
    
}
