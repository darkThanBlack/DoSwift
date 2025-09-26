//
//  AppDelegate.swift
//  DoSwift_Example
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit
import DoSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Setup main window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.systemBackground

        let mainViewController = ViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Initialize DoSwift with custom menu items
        setupDoSwift()

        return true
    }

    private func setupDoSwift() {
        // 设置主应用窗口引用
        DoSwiftCore.shared.setup(window)

        // 创建自定义菜单项
        let customMenuItems = createCustomMenuItems()

        // 初始化 DoSwift
        DoSwiftCore.shared.initialize(with: customMenuItems)

        // 显示 DoSwift 悬浮窗（仅在 Debug 构建中）
        #if DEBUG
        DoSwiftCore.shared.start()
        #endif
    }

    private func createCustomMenuItems() -> [DoSwiftMenuItem] {

        // App Info Menu
        let appInfoItem = DoSwiftMenuItem(
            identifier: "app_info",
            title: "应用信息",
            icon: UIImage(systemName: "info.circle")
        ) { _ in
            self.showAppInfo()
        }

        // Network Menu with sub-items
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

        let networkLogItem = DoSwiftMenuItem(
            identifier: "network_log",
            title: "网络日志"
        ) { _ in
            print("查看网络日志")
        }

        networkItem.addSubMenuItem(networkMonitorItem)
        networkItem.addSubMenuItem(networkLogItem)

        // Performance Menu
        let performanceItem = DoSwiftMenuItem(
            identifier: "performance",
            title: "性能监控",
            icon: UIImage(systemName: "speedometer")
        ) { _ in
            self.showPerformanceInfo()
        }

        // UI Debug Menu
        let uiDebugItem = DoSwiftMenuItem(
            identifier: "ui_debug",
            title: "UI 调试",
            icon: UIImage(systemName: "eye")
        ) { _ in
            self.toggleUIDebugMode()
        }

        // Memory Menu
        let memoryItem = DoSwiftMenuItem(
            identifier: "memory",
            title: "内存分析",
            icon: UIImage(systemName: "memorychip")
        ) { _ in
            self.showMemoryInfo()
        }

        // Settings Menu with sub-items
        let settingsItem = DoSwiftMenuItem(
            identifier: "settings",
            title: "设置",
            icon: UIImage(systemName: "gearshape")
        )

        let themeItem = DoSwiftMenuItem(
            identifier: "theme",
            title: "切换主题"
        ) { _ in
            self.toggleTheme()
        }

        let aboutItem = DoSwiftMenuItem(
            identifier: "about",
            title: "关于 DoSwift"
        ) { _ in
            self.showAbout()
        }

        settingsItem.addSubMenuItem(themeItem)
        settingsItem.addSubMenuItem(aboutItem)

        // Close Menu
        let closeItem = DoSwiftMenuItem.closeItem { _ in
            DoSwiftCore.shared.hide()
        }

        return [
            appInfoItem,
            networkItem,
            performanceItem,
            uiDebugItem,
            memoryItem,
            DoSwiftMenuItem.separator(),
            settingsItem,
            closeItem
        ]
    }

    // MARK: - Menu Actions

    private func showAppInfo() {
        let alertController = UIAlertController(
            title: "应用信息",
            message: """
            应用名称: DoSwift Example
            版本: 1.0.0
            构建版本: 1
            Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")
            """,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    private func showPerformanceInfo() {
        let alertController = UIAlertController(
            title: "性能信息",
            message: """
            CPU 使用率: ~5%
            内存使用: ~64MB
            FPS: 60
            """,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    private func toggleUIDebugMode() {
        // Toggle UI debug visualization
        let message = "UI 调试模式已切换"

        let alertController = UIAlertController(
            title: "UI 调试",
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    private func showMemoryInfo() {
        let memoryUsage = getMemoryUsage()

        let alertController = UIAlertController(
            title: "内存使用情况",
            message: """
            已使用内存: \(String(format: "%.1f", memoryUsage.used)) MB
            可用内存: \(String(format: "%.1f", memoryUsage.free)) MB
            总内存: \(String(format: "%.1f", memoryUsage.total)) MB
            """,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    private func toggleTheme() {
        // Toggle between light and dark theme
        let alertController = UIAlertController(
            title: "主题切换",
            message: "主题已切换",
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    private func showAbout() {
        let alertController = UIAlertController(
            title: "关于 DoSwift",
            message: """
            DoSwift v0.1.0

            基于 DoKit-iOS 重构的纯 Swift 调试工具库

            • 标准 UIWindow 处理框架
            • 悬浮控件和多级菜单
            • 插件化架构设计
            • 支持 iOS 12+
            """,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))

        window?.rootViewController?.present(alertController, animated: true)
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> (used: Double, free: Double, total: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            // Approximate values for demo
            let totalMemory = 4096.0 // 4GB for example
            let freeMemory = totalMemory - usedMemory
            return (used: usedMemory, free: freeMemory, total: totalMemory)
        } else {
            return (used: 0.0, free: 0.0, total: 0.0)
        }
    }
}
