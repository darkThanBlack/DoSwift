//
//  HierarchyInspectorController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol HierarchyInspectorDelegate: AnyObject {
    func inspectorDidRequestClose(_ controller: HierarchyInspectorController)
    func inspectorDidRequestDetailView(_ controller: HierarchyInspectorController, for view: UIView)
}

/// UI 结构检查器控制器 - 正确处理窗口区分和事件拦截
class HierarchyInspectorController: UIViewController {

    // MARK: - Properties

    weak var delegate: HierarchyInspectorDelegate?

    private var overlayView: HierarchyInspectorOverlayView!
    private var driftView: DriftView!
    private var selectedView: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInspector()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exitInspectorMode()
    }

    // MARK: - Setup

    private func setupInspector() {
        guard let appWindow = DoSwiftCore.shared.appWindow else {
            print("无法获取主应用窗口")
            return
        }

        // 创建 DriftView
        setupDriftView()

        // 创建覆盖层视图
        overlayView = HierarchyInspectorOverlayView(frame: appWindow.bounds)
        overlayView.configure(targetWindow: appWindow, driftView: driftView)
        overlayView.delegate = self

        // 添加到主应用窗口
        appWindow.addSubview(overlayView)

        // 更新 DoSwift 窗口的 noResponseViews
        updateNoResponseViews()

        // 显示提示
        showInstructionAlert()
    }

    private func setupDriftView() {
        driftView = DriftView()
        driftView.delegate = self
        driftView.isEdgeAbsorbEnabled = false  // 自由拖动
        driftView.isFadeEnabled = false        // 不淡化
    }

    private func exitInspectorMode() {
        overlayView?.removeFromSuperview()
        overlayView = nil
        driftView = nil

        // 恢复 DoSwift 窗口的 noResponseViews
        restoreNoResponseViews()
    }

    // MARK: - Window Management

    private func updateNoResponseViews() {
        guard let doSwiftWindow = DoSwiftCore.shared.window else { return }

        // 将当前控制器的 view 添加到 noResponseViews，保证事件不被 DoSwift 窗口拦截
        doSwiftWindow.addNoResponseView(self.view)
    }

    private func restoreNoResponseViews() {
        guard let doSwiftWindow = DoSwiftCore.shared.window else { return }

        // 从 noResponseViews 中移除当前控制器的 view
        doSwiftWindow.removeNoResponseView(self.view)
    }

    // MARK: - UI Actions

    private func showInstructionAlert() {
        let alert = UIAlertController(
            title: "UI 结构检查器",
            message: "• 拖拽浮窗按钮显示坐标辅助线\n• 拖拽结束时检测控件\n• 单击浮窗按钮切换检查器\n• 点击关闭按钮退出",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "开始检查", style: .default))

        // 从 DoSwift 窗口弹出
        if let doSwiftVC = DoSwiftCore.shared.mainController {
            doSwiftVC.present(alert, animated: true)
        }
    }

    // MARK: - View Finding

    private func findViewAtLocation(_ location: CGPoint) -> UIView? {
        guard let appWindow = DoSwiftCore.shared.appWindow else { return nil }

        // 转换坐标到主应用窗口
        let locationInWindow = appWindow.convert(location, from: overlayView)

        // 递归查找最深层的视图
        return findDeepestViewAtLocation(locationInWindow, in: appWindow)
    }

    private func findDeepestViewAtLocation(_ location: CGPoint, in view: UIView) -> UIView? {
        // 跳过 DoSwift 相关的视图
        if String(describing: type(of: view)).contains("DoSwift") {
            return nil
        }

        // 检查点击是否在当前视图范围内
        let localPoint = view.convert(location, from: DoSwiftCore.shared.appWindow)
        if !view.bounds.contains(localPoint) {
            return nil
        }

        // 递归检查子视图
        for subview in view.subviews.reversed() {
            if let deeperView = findDeepestViewAtLocation(location, in: subview) {
                return deeperView
            }
        }

        return view
    }

    private func selectView(_ view: UIView) {
        selectedView = view
        overlayView.updateSelectedView(view)
        overlayView.highlightView(view)
        overlayView.showInspector()
    }

    private func showParentViews(for view: UIView) {
        let alert = UIAlertController(title: "父视图", message: nil, preferredStyle: .actionSheet)

        var currentView: UIView? = view.superview
        var level = 1

        while let parentView = currentView {
            let title = "Level \(level): \(String(describing: type(of: parentView)))"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectView(parentView)
            })

            currentView = parentView.superview
            level += 1

            if level > 10 { break }
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        // 从目标窗口的根控制器弹出
        if let rootViewController = DoSwiftCore.shared.appWindow?.rootViewController {
            var presentingVC = rootViewController
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        }
    }

    private func showSubviews(for view: UIView) {
        let subviews = view.subviews.filter { !String(describing: type(of: $0)).contains("DoSwift") }

        if subviews.isEmpty {
            let alert = UIAlertController(title: "子视图", message: "该视图没有子视图", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))

            if let rootViewController = DoSwiftCore.shared.appWindow?.rootViewController {
                var presentingVC = rootViewController
                while let presented = presentingVC.presentedViewController {
                    presentingVC = presented
                }
                presentingVC.present(alert, animated: true)
            }
            return
        }

        let alert = UIAlertController(title: "子视图", message: nil, preferredStyle: .actionSheet)

        for (index, subview) in subviews.enumerated() {
            let title = "\(index + 1): \(String(describing: type(of: subview)))"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectView(subview)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let rootViewController = DoSwiftCore.shared.appWindow?.rootViewController {
            var presentingVC = rootViewController
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        }
    }
}

// MARK: - DriftViewDelegate

extension HierarchyInspectorController: DriftViewDelegate {
    func driftViewDidTap(_ driftView: DriftView) {
        overlayView.toggleInspector()
    }

    func driftViewDidBeginDrag(_ driftView: DriftView) {
        // 开始拖拽时可以做一些准备工作
    }

    func driftViewDidDrag(_ driftView: DriftView, location: CGPoint) {
        overlayView.updateDragLocation(location)
    }

    func driftViewDidEndDrag(_ driftView: DriftView, location: CGPoint) {
        overlayView.hideDragIndicators()

        // 拖拽结束时触发检测
        if let hitView = findViewAtLocation(location) {
            print("检测到视图 - \(String(describing: type(of: hitView)))")
            print("视图 frame - \(hitView.frame)")
            print("视图 backgroundColor - \(String(describing: hitView.backgroundColor))")
            print("视图层级 - \(hitView.superview != nil ? String(describing: type(of: hitView.superview!)) : "nil")")
            if let label = hitView as? UILabel {
                print("UILabel text - '\(label.text ?? "nil")'")
            }
            if let button = hitView as? UIButton {
                print("UIButton title - '\(button.title(for: .normal) ?? "nil")'")
            }
            print("---")

            // 注释原有逻辑，更改为打印
            // selectView(hitView)
        }
    }
}

// MARK: - HierarchyInspectorOverlayViewDelegate

extension HierarchyInspectorController: HierarchyInspectorOverlayViewDelegate {
    func overlayViewDidRequestClose(_ overlayView: HierarchyInspectorOverlayView) {
        delegate?.inspectorDidRequestClose(self)
    }

    func overlayViewDidRequestMoreInfo(_ overlayView: HierarchyInspectorOverlayView) {
        if let selectedView = selectedView {
            delegate?.inspectorDidRequestDetailView(self, for: selectedView)
        }
    }

    func overlayViewDidRequestParentViews(_ overlayView: HierarchyInspectorOverlayView) {
        if let selectedView = selectedView {
            showParentViews(for: selectedView)
        }
    }

    func overlayViewDidRequestSubviews(_ overlayView: HierarchyInspectorOverlayView) {
        if let selectedView = selectedView {
            showSubviews(for: selectedView)
        }
    }
}