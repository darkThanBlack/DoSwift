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

        // 使用默认菜单初始化（也可以传入自定义菜单）
        DoSwiftCore.shared.initialize()

        // 可选：添加自定义菜单项到默认菜单
        addCustomMenuItems()

        // 显示 DoSwift 悬浮窗（仅在 Debug 构建中）
        #if DEBUG
        DoSwiftCore.shared.start()
        #endif
    }

    private func addCustomMenuItems() {
        // 示例：添加自定义菜单项
        let customItem = DoSwiftMenuItem(
            identifier: "custom_example",
            title: "示例功能",
            icon: UIImage(systemName: "star.fill")
        ) { _ in
            self.showCustomFeature()
        }

        DoSwiftCore.shared.addMenuItem(customItem)
    }

    private func showCustomFeature() {
        let alertController = UIAlertController(
            title: "自定义功能",
            message: "这是 Example 项目添加的自定义功能示例",
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
