//
//  DoSwiftCore.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 核心管理器，参考 Drift 架构设计
public class DoSwiftCore {

    public static let shared = DoSwiftCore()
    private init() {}

    // MARK: - Properties

    public var window: DoSwiftWindow?
    weak var mainController: DoSwiftMainViewController?

    /// 工具目录，按分组存放（一个分组即 DoKit 的一个模块）
    public var toolGroups: [DoSwiftToolGroup] = []

    // MARK: - Public Interface

    /// 设置主应用窗口引用（转发到全局 DoSwiftContext）
    public func setup(_ window: UIWindow?) {
        DoSwiftContext.shared.setup(window)
    }

    /// 初始化 DoSwift
    public func initialize(with toolGroups: [DoSwiftToolGroup]? = nil) {
        self.toolGroups = toolGroups ?? DoSwiftToolCatalog.defaultToolGroups()
        attachDefaultActions(to: self.toolGroups)
        prepare()
    }

    /// 显示悬浮窗
    public func start() {
        prepare()
        window?.isHidden = false
    }

    /// 隐藏悬浮窗
    public func stop() {
        window?.isHidden = true
    }

    /// 便捷方法
    public func show() { start() }
    public func hide() { stop() }

    /// 追加一个工具分组
    public func addToolGroup(_ group: DoSwiftToolGroup) {
        toolGroups.append(group)
        attachDefaultActions(to: [group])
        mainController?.updateToolGroups(toolGroups)
    }

    /// 移除指定标题的工具分组
    public func removeToolGroup(titled title: String) {
        toolGroups.removeAll { $0.title == title }
        mainController?.updateToolGroups(toolGroups)
    }

    /// 往指定分组里追加一个工具
    public func addTool(_ tool: DoSwiftMenuItem, toGroupTitled title: String) {
        guard let index = toolGroups.firstIndex(where: { $0.title == title }) else { return }
        toolGroups[index].items.append(tool)
        attachDefaultActions(to: [toolGroups[index]])
        mainController?.updateToolGroups(toolGroups)
    }

    /// 按标识移除工具
    public func removeTool(withIdentifier identifier: String) {
        for index in toolGroups.indices {
            toolGroups[index].items.removeAll { $0.identifier == identifier }
        }
        mainController?.updateToolGroups(toolGroups)
    }

    /// 推送视图控制器
    public func pushViewController(_ viewController: UIViewController, animated: Bool = true) {
        guard let navController = mainController?.navigationController else { return }
        navController.pushViewController(viewController, animated: animated)
    }

    /// 弹出视图控制器
    public func popViewController(animated: Bool = true) {
        guard let navController = mainController?.navigationController else { return }
        navController.popViewController(animated: animated)
    }

    // MARK: - Private Methods

    private func prepare() {
        guard window == nil else { return }

        // 兜底：裸调 start() 也必须拿到默认目录。
        // 之前 Example 从没调用过 initialize()，menuItems 一直是空的，
        // 于是 showMenu() 的 guard 直接返回——点手柄毫无反应。那类问题不该重演。
        if toolGroups.isEmpty {
            toolGroups = DoSwiftToolCatalog.defaultToolGroups()
        }
        attachDefaultActions(to: toolGroups)

        // 创建窗口
        let doSwiftWindow = DoSwiftWindow(frame: UIScreen.main.bounds)
        doSwiftWindow.isHidden = true
        doSwiftWindow.backgroundColor = .clear
        doSwiftWindow.windowLevel = .normal

        // 兼容 iOS 13+ Scene
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                doSwiftWindow.windowScene = scene
            }
        }

        // 创建根控制器
        let root = DoSwiftMainViewController()
        root.toolGroups = toolGroups

        let nav = UINavigationController(rootViewController: root)
        nav.isNavigationBarHidden = true

        doSwiftWindow.rootViewController = nav

        // 设置引用
        mainController = root
        window = doSwiftWindow

        // 重要：必须最后调用，避免导航控制器被销毁
        doSwiftWindow.addNoResponseView(root.view)
    }

    /// 把行为挂到目录里对应的工具上。
    ///
    /// 目录本身**只有数据**（每个 `actionHandler` 都是 nil），行为集中在这里，
    /// 于是工具轨只需认识 `DoSwiftToolGroup`，完全不必知道任何工具的存在。
    /// 已经有 handler 的不覆盖，宿主可以先挂自己的实现。
    private func attachDefaultActions(to groups: [DoSwiftToolGroup]) {
        for group in groups {
            for tool in group.items where tool.actionHandler == nil {
                switch tool.identifier {
                case "app_info":
                    tool.actionHandler = { [weak self] _ in self?.showAppInfo() }
                case "ui_hierarchy":
                    tool.actionHandler = { [weak self] _ in self?.showUIHierarchy() }
                default:
                    break
                }
            }
        }
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

        // 从顶层控制器弹出
        if let topController = topMostController() {
            topController.present(alertController, animated: true)
        }
    }

    private func showUIHierarchy() {
        let inspectorController = HierarchyInspectorController()
        pushViewController(inspectorController, animated: true)
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

        // 优先使用主应用窗口，其次使用悬浮窗
        return recursion(DoSwiftContext.shared.appWindow?.rootViewController) ?? recursion(window?.rootViewController)
    }
}
