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

    /// 唯一入口：传入业务 App 的 window 与自定义菜单项，完成初始化并显示。
    ///
    /// 默认菜单写死在 `defaultGroups()`；业务传入的自定义项会**合并进同一个分组**，
    /// 追加在默认分组之后。运行期间不再改动。
    public func start(appWindow: UIWindow?, items: [DoSwiftMenuItem] = []) {
        self.appWindow = appWindow

        menuGroups = DoSwiftCore.defaultGroups()
        if !items.isEmpty {
            menuGroups.append(DoSwiftMenuGroup(title: DoSwiftCore.customGroupTitle, items: items))
        }
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

    private func prepare() {
        guard window == nil else { return }

        // 兜底：没调过 start 就直接 show 也要能拿到默认菜单。
        // 之前 Example 从没调用过初始化、菜单一直是空的，点手柄毫无反应——
        // 那类「静默失效」不该重演。
        if menuGroups.isEmpty {
            menuGroups = DoSwiftCore.defaultGroups()
        }
        attachActions()

        // Scene 绑定由 OverlayWindow 自己处理（按前台活跃状态过滤）
        let overlayWindow = OverlayWindow(frame: UIScreen.main.bounds, level: .normal)
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
                    item.actionHandler = { [weak self] _ in self?.showAppInfo() }
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

        let performance = DoSwiftMenuGroup(title: "性能检测", items: [
            item("fps",             "帧率",         "speedometer"),
            item("cpu",             "CPU",          "gauge"),
            item("memory",          "内存",         "cube.box"),
            item("network",         "网络",         "wifi"),
            item("crash",           "Crash",        "exclamationmark.triangle"),
            item("sub_thread_ui",   "子线程UI",     "rectangle.on.rectangle"),
            item("anr",             "卡顿",         "hourglass"),
            item("method_use_time", "Load耗时",     "clock"),
            item("large_image",     "大图检测",     "photo"),
            item("start_time",      "启动耗时",     "power"),
            item("memory_leak",     "内存泄漏",     "drop.triangle"),
            item("ui_profile",      "UI层级",       "square.stack.3d.up"),
            item("time_profile",    "函数耗时",     "timer"),
            item("weak_network",    "模拟弱网",     "wifi.exclamationmark"),
        ])

        let visual = DoSwiftMenuGroup(title: "视觉工具", items: [
            item("color_pick",   "取色器",   "eyedropper"),
            item("view_check",   "组件检查", "viewfinder"),
            item("view_align",   "对齐标尺", "arrow.left.and.right"),
            item("view_metrics", "布局边框", "rectangle"),
            item("ui_hierarchy", "UI结构",   "list.bullet.indent"),
        ])

        let weex = DoSwiftMenuGroup(title: "Weex", items: [
            item("weex_log",     "日志",    "list.dash"),
            item("weex_storage", "缓存",    "tray"),
            item("weex_info",    "信息",    "info"),
            item("weex_devtool", "DevTool", "hammer"),
        ])

        let platform = DoSwiftMenuGroup(title: "平台工具", items: [
            item("mock",      "Mock数据", "wand.and.stars"),
            item("health",    "健康体检", "waveform.path.ecg"),
            item("file_sync", "文件同步", "arrow.2.circlepath"),
        ])

        return [common, performance, visual, weex, platform]
    }

    private func showAppInfo() {
        let alertController = UIAlertController(
            title: "应用信息",
            message: """
            DoSwift v0.1.0
            纯 Swift iOS 调试工具库
            """,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        if let topController = topMostController() {
            topController.present(alertController, animated: true)
        }
    }

    /// 获取当前最顶层的控制器
    private func topMostController() -> UIViewController? {
        func recursion(_ vc: UIViewController?) -> UIViewController? {
            if let nav = vc as? UINavigationController {
                return recursion(nav.visibleViewController)
            }
            if let tab = vc as? UITabBarController {
                return recursion(tab.selectedViewController)
            }
            if let presented = vc?.presentedViewController {
                return recursion(presented)
            }
            return vc
        }

        return recursion(appWindow?.rootViewController) ?? recursion(window?.rootViewController)
    }
}
