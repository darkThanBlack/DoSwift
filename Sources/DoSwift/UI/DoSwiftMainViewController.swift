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

    /// 菜单项配置
    var menuItems: [DoSwiftMenuItem] = []

    /// 悬浮按钮视图
    lazy var driftView: DoSwiftDriftView = {
        let view = DoSwiftDriftView()
        view.delegate = self
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .clear

        setupDriftView()
    }

    // MARK: - Public Methods

    /// 更新菜单项
    func updateMenuItems(_ items: [DoSwiftMenuItem]) {
        menuItems = items
        driftView.menuItems = items
    }

    // MARK: - Private Methods

    private func setupDriftView() {
        view.addSubview(driftView)

        let driftSize = driftView.sizeThatFits(UIScreen.main.bounds.size)

        // 从 UserDefaults 恢复位置
        let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: DoSwiftUserDefaults.driftFrameKey) as? [String: CGFloat]

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

        // 设置菜单项
        driftView.menuItems = menuItems
    }
}

// MARK: - DoSwiftDriftViewDelegate

extension DoSwiftMainViewController: DoSwiftDriftViewDelegate {

    func driftViewDidTap(_ driftView: DoSwiftDriftView) {
        // 显示菜单
        showMenu()
    }

    private func showMenu() {
        guard !menuItems.isEmpty else { return }

        // 创建菜单控制器
        let menuController = DoSwiftMenuViewController()
        menuController.menuItems = menuItems
        menuController.delegate = self

        // 推送菜单
        navigationController?.pushViewController(menuController, animated: true)
    }
}

// MARK: - DoSwiftMenuViewControllerDelegate

extension DoSwiftMainViewController: DoSwiftMenuViewControllerDelegate {

    func menuViewController(_ controller: DoSwiftMenuViewController, didSelectMenuItem menuItem: DoSwiftMenuItem) {
        // 如果有子菜单，推送子菜单
        if menuItem.hasSubMenu {
            let subMenuController = DoSwiftMenuViewController()
            subMenuController.menuItems = menuItem.subMenuItems
            subMenuController.title = menuItem.title
            subMenuController.delegate = self
            navigationController?.pushViewController(subMenuController, animated: true)
        } else {
            // 执行菜单项动作
            menuItem.performAction()

            // 只有关闭动作才返回主界面，其他动作（如打开新页面）保持在当前状态
            if menuItem.identifier == "close" {
                navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    func menuViewControllerDidRequestClose(_ controller: DoSwiftMenuViewController) {
        navigationController?.popToRootViewController(animated: true)
    }
}