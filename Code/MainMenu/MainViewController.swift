//
//  MainViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2025/09/26
//  Copyright © 2025 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {
    
    @objc(DOMainViewController)
    class MainViewController: UIViewController {

        var menuGroups: [DO.MenuGroup] = [] {
            didSet {
                panelView.setMenuGroups(menuGroups)
            }
        }

        lazy var handleView: DO.MenuHandle = {
            let view = DO.MenuHandle()
            view.delegate = self
            return view
        }()

        private lazy var panelView: DO.MenuPanel = {
            let view = DO.MenuPanel()
            view.delegate = self
            return view
        }()

        private var lastLayoutSize: CGSize = .zero

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

        private func setupDoSwiftMenuHandle() {
            view.addSubview(handleView)

            let handleSize = handleView.sizeThatFits(UIScreen.main.bounds.size)

            let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: DO.MenuHandle.handleFrameKey) as? [String: CGFloat]

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
}

extension DO.MainViewController: DO.MenuHandleDelegate {

    func menuHandleDidBeginDrag(_ handleView: DO.MenuHandle) {
        setPanelOpen(false)
    }

    func menuHandleDidTap(_ handleView: DO.MenuHandle) {
        toggleMenu()
    }
}

extension DO.MainViewController: DO.MenuPanelDelegate {

    func menuPanel(_ panel: DO.MenuPanel, didSelect item: DO.MenuItem) {
        setPanelOpen(false)
        item.actionHandler?()
    }

    func menuPanelDidSelectClose(_ panel: DO.MenuPanel) {
        setPanelOpen(false)
    }
}
