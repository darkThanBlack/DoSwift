//
//  DoSwiftMainViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 主视图控制器，参考 DriftMainViewController 设计
class DoSwiftMainViewController: UIViewController {

    // MARK: - Properties

    /// 工具目录，按分组
    var toolGroups: [DoSwiftToolGroup] = [] {
        didSet {
            railView.setToolGroups(toolGroups)
        }
    }

    /// 悬浮按钮视图
    lazy var driftView: DriftView = {
        let view = DriftView()
        view.delegate = self
        return view
    }()

    /// 贴边工具轨
    private lazy var railView: DoSwiftToolRailView = {
        let view = DoSwiftToolRailView()
        view.onSelectItem = { [weak self] tool in
            // 先收起再执行：工具的页面/弹窗是从业务 window 呈现的，
            // 轨道留在屏幕上会盖住它的一侧。
            self?.railView.hide(animated: true)
            tool.performAction()
        }
        return view
    }()

    /// 拖拽起点，用于把「轻点」和「拖拽」区分开
    private var dragStartOrigin: CGPoint = .zero

    /// 上一次布局的尺寸，只在尺寸真的变了时才重新吸附
    private var lastLayoutSize: CGSize = .zero

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .clear

        setupDriftView()
        setupRailView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 尺寸变化（旋转、换设备）后重新吸附。手柄的位置是轨道停靠边的依据，
        // 而 setupDriftView() 只在 viewDidLoad 里摆过一次，旋转后手柄可能已经在屏幕外。
        let size = view.bounds.size
        if size != lastLayoutSize {
            lastLayoutSize = size
            driftView.fireAbsorb()
        }

        if railView.isOpen {
            relayoutRail()
        }
    }

    // MARK: - Public Methods

    /// 更新工具目录
    func updateToolGroups(_ groups: [DoSwiftToolGroup]) {
        toolGroups = groups
    }

    // MARK: - Private Methods

    private func setupDriftView() {
        view.addSubview(driftView)

        let driftSize = driftView.sizeThatFits(UIScreen.main.bounds.size)

        // 从 UserDefaults 恢复位置
        let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: UserDefaults.driftFrameKey) as? [String: CGFloat]

        let defaultX = view.bounds.width - driftSize.width - 20
        let defaultY = view.bounds.height * 0.3

        driftView.frame = CGRect(
            x: savedFrame?["x"] ?? defaultX,
            y: savedFrame?["y"] ?? defaultY,
            width: driftSize.width,
            height: driftSize.height
        )

        // 初始化时执行吸附
        driftView.fireAbsorb()
    }

    private func setupRailView() {
        // 必须是 view 的直接子视图，且 frame 不能等于 view.bounds：
        // DoSwiftWindow 的事件穿透依赖「命中视图恰好 === root.view」这一判断。
        // 一旦外面套一层全屏容器，容器会变成命中视图且未注册，整个 App 就点不动了。
        view.addSubview(railView)
        railView.setToolGroups(toolGroups)
    }

    private func toggleToolRail() {
        if railView.isOpen {
            railView.hide(animated: true)
        } else {
            relayoutRail()
            // 手柄可能被面板盖住，提到最前保证始终可点
            view.bringSubviewToFront(driftView)
            railView.show(animated: true)
        }
    }

    private func relayoutRail() {
        railView.relayout(
            edge: currentDockEdge(),
            handleFrame: driftView.frame,
            containerBounds: view.bounds,
            safeAreaInsets: view.safeAreaInsets
        )
    }

    /// 手柄在哪半边就贴哪条边，与 DriftView.absorbHorizontal 的判定一致
    private func currentDockEdge() -> DoSwiftToolRailView.Edge {
        return driftView.frame.midX > view.bounds.midX ? .right : .left
    }
}

// MARK: - DriftViewDelegate

extension DoSwiftMainViewController: DriftViewDelegate {

    func driftViewDidBeginDrag(_ driftView: DriftView) {
        dragStartOrigin = driftView.frame.origin
    }

    func driftViewDidDrag(_ driftView: DriftView, location: CGPoint) {
        // 注意：touchesBegan 也会触发 didBeginDrag，所以不能拿它当拖拽信号，
        // 只能看位置是不是真的动了。
        guard railView.isOpen else { return }

        // 阈值与 DriftView 内部判定轻点/拖拽用的是同一个常量，避免两边错位产生灰区
        let moved = abs(driftView.frame.origin.x - dragStartOrigin.x)
            + abs(driftView.frame.origin.y - dragStartOrigin.y)
        if moved > DriftView.dragThreshold {
            railView.hide(animated: true)
        }
    }

    func driftViewDidEndDrag(_ driftView: DriftView, location: CGPoint) {

    }

    func driftViewDidTap(_ driftView: DriftView) {
        toggleToolRail()
    }
}
