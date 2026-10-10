//
//  DoSwiftMainViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 主视图控制器（悬浮窗的根控制器，承载手柄与主菜单面板），
class DoSwiftMainViewController: UIViewController {

    // MARK: - Properties

    /// 工具目录，按分组
    var menuGroups: [DoSwiftMenuGroup] = [] {
        didSet {
            panelView.setMenuGroups(menuGroups)
        }
    }

    /// 悬浮按钮视图
    lazy var handleView: DoSwiftMenuHandle = {
        let view = DoSwiftMenuHandle()
        view.delegate = self
        return view
    }()

    /// 贴边主菜单面板
    private lazy var panelView: DoSwiftMenuPanel = {
        let view = DoSwiftMenuPanel()
        view.delegate = self
        return view
    }()

    /// 上一次布局的尺寸，只在尺寸真的变了时才重新吸附
    private var lastLayoutSize: CGSize = .zero

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        setupDoSwiftMenuHandle()
        setupPanel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 尺寸变化（旋转、换设备）后重新吸附。手柄的位置是面板停靠边的依据，
        // 而 setupDoSwiftMenuHandle() 只在 viewDidLoad 里摆过一次，旋转后手柄可能已经在屏幕外。
        let size = view.bounds.size
        if size != lastLayoutSize {
            lastLayoutSize = size
            handleView.settle()
        }

        if panelView.isOpen {
            relayoutPanel()
        }
    }

    // MARK: - Private Methods

    private func setupDoSwiftMenuHandle() {
        view.addSubview(handleView)

        let handleSize = handleView.sizeThatFits(UIScreen.main.bounds.size)

        // 从 UserDefaults 恢复位置
        let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: DoSwiftMenuHandle.handleFrameKey) as? [String: CGFloat]

        let defaultX = view.bounds.width - handleSize.width - 20
        let defaultY = view.bounds.height * 0.3

        handleView.frame = CGRect(
            x: savedFrame?["x"] ?? defaultX,
            y: savedFrame?["y"] ?? defaultY,
            width: handleSize.width,
            height: handleSize.height
        )

        // 初始化时执行吸附
        handleView.settle()
    }

    private func setupPanel() {
        // 必须是 view 的直接子视图，且 frame 不能等于 view.bounds：
        // OverlayWindow 的事件穿透依赖「命中视图恰好 === root.view」这一判断。
        // 一旦外面套一层全屏容器，容器会变成命中视图且未注册，整个 App 就点不动了。
        view.addSubview(panelView)
        panelView.setMenuGroups(menuGroups)
    }

    /// 面板开合的**唯一入口**，顺带驱动手柄的空闲淡化。
    ///
    /// 收敛成一个入口不只是整洁：`isFadeEnabled` 只有在这里被写，才不会出现
    /// 「面板已经关了、手柄却永远挂起」这种没人负责恢复的状态。
    /// `guard` 保证只有真实迁移才写一次，所以不需要配对计数。
    private func setPanelOpen(_ open: Bool) {
        guard panelView.isOpen != open else { return }

        if open {
            relayoutPanel()
            // 手柄可能被面板盖住，提到最前保证始终可点
            view.bringSubviewToFront(handleView)
            panelView.show(animated: true)
        } else {
            panelView.hide(animated: true)
        }

        // 展开期间手柄恒亮，关闭后才重新开始计数
        handleView.isFadeEnabled = !open
    }

    private func toggleMenu() {
        setPanelOpen(!panelView.isOpen)
    }

    private func relayoutPanel() {
        panelView.relayout(handleFrame: handleView.frame)
    }
}

// MARK: - DoSwiftMenuHandleDelegate

extension DoSwiftMainViewController: DoSwiftMenuHandleDelegate {

    func menuHandleDidBeginDrag(_ handleView: DoSwiftMenuHandle) {
        // pan 成立即代表用户在真的拖手柄，面板在它旁边会碍事，直接收起
        setPanelOpen(false)
    }

    func menuHandleDidTap(_ handleView: DoSwiftMenuHandle) {
        toggleMenu()
    }
}

// MARK: - DoSwiftMenuPanelDelegate

extension DoSwiftMainViewController: DoSwiftMenuPanelDelegate {

    func menuPanel(_ panel: DoSwiftMenuPanel, didSelect item: DoSwiftMenuItem) {
        // 先收起再执行：工具的页面/弹窗是从业务 window 呈现的，
        // 面板留在屏幕上会盖住它的一侧。
        setPanelOpen(false)
        item.performAction()
    }

    func menuPanelDidSelectClose(_ panel: DoSwiftMenuPanel) {
        // 跟点手柄、拖手柄一样，只是收起面板的又一个入口——必须走同一个闸口，
        // 否则手柄的 isFadeEnabled 没人恢复。
        setPanelOpen(false)
    }
}
