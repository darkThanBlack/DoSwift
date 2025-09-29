//
//  DoSwiftHierarchyInspectorController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构检查器控制器 - 正确处理窗口区分和事件拦截
public class DoSwiftHierarchyInspectorController: UIViewController {

    // MARK: - Properties

    private var overlayView: DoSwiftHierarchyInspectorOverlayView!
    private var targetWindow: UIWindow?

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupInspector()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exitInspectorMode()
    }

    // MARK: - Setup

    private func setupInspector() {
        // 获取主应用窗口 (不是 DoSwift 窗口)
        targetWindow = getMainAppWindow()

        guard let targetWindow = targetWindow else {
            print("DoSwift: 无法获取主应用窗口")
            return
        }

        // 创建覆盖层视图
        overlayView = DoSwiftHierarchyInspectorOverlayView(frame: targetWindow.bounds)
        overlayView.configure(targetWindow: targetWindow)
        overlayView.onClose = { [weak self] in
            self?.showDetailedHierarchy()
        }

        // 添加到主应用窗口
        targetWindow.addSubview(overlayView)

        // 更新 DoSwift 窗口的 noResponseViews
        updateNoResponseViews()

        // 显示提示
        showInstructionAlert()
    }

    private func exitInspectorMode() {
        overlayView?.removeFromSuperview()
        overlayView = nil

        // 恢复 DoSwift 窗口的 noResponseViews
        restoreNoResponseViews()
    }

    // MARK: - Window Management

    private func getMainAppWindow() -> UIWindow? {
        var allWindows: [UIWindow] = []

        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    allWindows.append(contentsOf: windowScene.windows)
                }
            }
        } else {
            allWindows = UIApplication.shared.windows
        }

        // 过滤出主应用窗口 (排除 DoSwift 窗口)
        let mainWindows = allWindows.filter { window in
            !String(describing: type(of: window)).contains("DoSwift") &&
            window.isKeyWindow == false || // 不是当前键窗口(DoSwift窗口)
            window.windowLevel == .normal
        }

        // 返回第一个主应用窗口
        return mainWindows.first ?? allWindows.first
    }

    private func updateNoResponseViews() {
        guard let doSwiftWindow = DoSwiftCore.shared.window,
              let overlayView = overlayView else { return }

        // 将覆盖层添加到 noResponseViews，确保事件不被 DoSwift 窗口拦截
        doSwiftWindow.addNoResponseView(overlayView)
    }

    private func restoreNoResponseViews() {
        guard let doSwiftWindow = DoSwiftCore.shared.window,
              let overlayView = overlayView else { return }

        // 从 noResponseViews 中移除覆盖层
        doSwiftWindow.removeNoResponseView(overlayView)
    }

    // MARK: - UI Actions

    private func showInstructionAlert() {
        let alert = UIAlertController(
            title: "UI 结构检查器",
            message: "• 点击屏幕任意位置选择控件\n• 拖拽显示坐标辅助线\n• 使用右侧浮窗按钮控制检查器\n• 点击 More Info 查看详细属性",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "开始检查", style: .default))

        // 从 DoSwift 窗口弹出
        if let doSwiftVC = DoSwiftCore.shared.mainController {
            doSwiftVC.present(alert, animated: true)
        }
    }

    private func showDetailedHierarchy() {
        // 退出检查器模式
        exitInspectorMode()

        // 推入详细层级页面
        let hierarchyViewController = DoSwiftHierarchyViewController()
        DoSwiftCore.shared.pushViewController(hierarchyViewController, animated: true)
    }
}