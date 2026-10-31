//
//  DoSwiftMainViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

class DoSwiftMainViewController: UIViewController {

    // MARK: - Properties

    var menuGroups: [DoSwiftMenuGroup] = [] {
        didSet {
            panelView.setMenuGroups(menuGroups)
        }
    }

    lazy var handleView: DoSwiftMenuHandle = {
        let view = DoSwiftMenuHandle()
        view.delegate = self
        return view
    }()

    private lazy var panelView: DoSwiftMenuPanel = {
        let view = DoSwiftMenuPanel()
        view.delegate = self
        return view
    }()

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

        let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: DoSwiftMenuHandle.handleFrameKey) as? [String: CGFloat]

        let defaultX = view.bounds.width - handleSize.width - 20
        let defaultY = view.bounds.height * 0.3

        handleView.frame = CGRect(
            x: savedFrame?["x"] ?? defaultX,
            y: savedFrame?["y"] ?? defaultY,
            width: handleSize.width,
            height: handleSize.height
        )

        handleView.settle()
    }

    private func setupPanel() {
        view.addSubview(panelView)
        panelView.setMenuGroups(menuGroups)
    }

    private func setPanelOpen(_ open: Bool) {
        guard panelView.isOpen != open else { return }

        if open {
            relayoutPanel()
            view.bringSubviewToFront(handleView)
            panelView.show(animated: true)
        } else {
            panelView.hide(animated: true)
        }

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
        setPanelOpen(false)
    }

    func menuHandleDidTap(_ handleView: DoSwiftMenuHandle) {
        toggleMenu()
    }
}

// MARK: - DoSwiftMenuPanelDelegate

extension DoSwiftMainViewController: DoSwiftMenuPanelDelegate {

    func menuPanel(_ panel: DoSwiftMenuPanel, didSelect item: DoSwiftMenuItem) {
        setPanelOpen(false)
        item.actionHandler?()
    }

    func menuPanelDidSelectClose(_ panel: DoSwiftMenuPanel) {
        setPanelOpen(false)
    }
}
