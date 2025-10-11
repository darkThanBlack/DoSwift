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

    weak var appWindow: UIWindow?
    public var window: DoSwiftWindow?
    weak var mainController: DoSwiftMainViewController?

    /// 菜单项配置
    public var menuItems: [DoSwiftMenuItem] = []

    // MARK: - Public Interface

    /// 设置主应用窗口引用
    public func setup(_ window: UIWindow?) {
        self.appWindow = window
    }

    /// 初始化 DoSwift
    public func initialize(with menuItems: [DoSwiftMenuItem]? = nil) {
        self.menuItems = menuItems ?? createDefaultMenuItems()
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

    /// 添加菜单项
    public func addMenuItem(_ menuItem: DoSwiftMenuItem) {
        menuItems.append(menuItem)
        mainController?.updateMenuItems(menuItems)
    }

    /// 移除菜单项
    public func removeMenuItem(withIdentifier identifier: String) {
        menuItems.removeAll { $0.identifier == identifier }
        mainController?.updateMenuItems(menuItems)
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
        root.menuItems = menuItems

        let nav = UINavigationController(rootViewController: root)
        nav.isNavigationBarHidden = true

        doSwiftWindow.rootViewController = nav

        // 设置引用
        mainController = root
        window = doSwiftWindow

        // 重要：必须最后调用，避免导航控制器被销毁
        doSwiftWindow.addNoResponseView(root.view)
    }

    private func createDefaultMenuItems() -> [DoSwiftMenuItem] {
        let appInfoItem = DoSwiftMenuItem(
            identifier: "app_info",
            title: "应用信息",
            icon: UIImage(systemName: "info.circle")
        ) { _ in
            self.showAppInfo()
        }

        let networkItem = DoSwiftMenuItem(
            identifier: "network",
            title: "网络工具",
            icon: UIImage(systemName: "network")
        )

        let networkMonitorItem = DoSwiftMenuItem(
            identifier: "network_monitor",
            title: "网络监控"
        ) { _ in
            print("启动网络监控")
        }

        networkItem.addSubMenuItem(networkMonitorItem)

        // UI 调试工具
        let uiDebugItem = DoSwiftMenuItem(
            identifier: "ui_debug",
            title: "UI 调试",
            icon: UIImage(systemName: "eye")
        )

        let hierarchyItem = DoSwiftMenuItem(
            identifier: "ui_hierarchy",
            title: "UI 结构查看器",
            icon: UIImage(systemName: "list.dash.header.rectangle")
        ) { _ in
            self.showUIHierarchy()
        }

        uiDebugItem.addSubMenuItem(hierarchyItem)

        let closeItem = DoSwiftMenuItem.closeItem { _ in
            self.hide()
        }

        return [appInfoItem, networkItem, uiDebugItem, closeItem]
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
        return recursion(appWindow?.rootViewController) ?? recursion(window?.rootViewController)
    }
}
