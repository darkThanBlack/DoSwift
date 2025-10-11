//
//  ViewController.swift
//  DoSwift_Example
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit
import DoSwift

class ViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "DoSwift Example"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "纯 Swift iOS 调试工具库演示"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Add UI elements to stack view
        contentStackView.addArrangedSubview(UIView()) // Top spacer
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.addArrangedSubview(createInfoCard())
        contentStackView.addArrangedSubview(createControlsCard())
        contentStackView.addArrangedSubview(createFeaturesCard())
        contentStackView.addArrangedSubview(UIView()) // Bottom spacer

        // Set spacer heights
        if let topSpacer = contentStackView.arrangedSubviews.first {
            topSpacer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }
        if let bottomSpacer = contentStackView.arrangedSubviews.last {
            bottomSpacer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content StackView
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func setupNavigationBar() {
        title = "DoSwift Demo"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add toggle button
        let toggleButton = UIBarButtonItem(
            title: "Toggle",
            style: .plain,
            target: self,
            action: #selector(toggleDoSwift)
        )
        navigationItem.rightBarButtonItem = toggleButton
    }

    // MARK: - Card Creation

    private func createInfoCard() -> UIView {
        let cardView = createCardView()

        let titleLabel = UILabel()
        titleLabel.text = "🎯 DoSwift 功能特性"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label

        let descriptionLabel = UILabel()
        descriptionLabel.text = """
        • 标准 UIWindow 处理框架
        • 悬浮控件和多级菜单系统
        • 参考 MOONAssistiveTouch 设计
        • 支持事件穿透和智能交互
        • 插件化架构，易于扩展
        """
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])

        return cardView
    }

    private func createControlsCard() -> UIView {
        let cardView = createCardView()

        let titleLabel = UILabel()
        titleLabel.text = "🎮 控制面板"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label

        let showButton = createButton(title: "显示 DoSwift", action: #selector(showDoSwift))
        let hideButton = createButton(title: "隐藏 DoSwift", action: #selector(hideDoSwift))
        let addMenuButton = createButton(title: "添加菜单项", action: #selector(addCustomMenuItem))

        let buttonStackView = UIStackView(arrangedSubviews: [showButton, hideButton, addMenuButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually

        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, buttonStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 16
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            showButton.heightAnchor.constraint(equalToConstant: 44),
            hideButton.heightAnchor.constraint(equalToConstant: 44),
            addMenuButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return cardView
    }

    private func createFeaturesCard() -> UIView {
        let cardView = createCardView()

        let titleLabel = UILabel()
        titleLabel.text = "📋 使用说明"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label

        let instructionsLabel = UILabel()
        instructionsLabel.text = """
        1. 点击右上角的悬浮按钮打开菜单
        2. 支持多级菜单导航，点击有箭头的项目进入子菜单
        3. 悬浮按钮支持拖拽移动和边缘吸附
        4. 长时间不操作会自动淡化按钮
        5. 点击菜单外区域或返回按钮可关闭菜单

        开发模式：
        • 使用 dev pods 进行本地开发
        • 支持 CocoaPods 和 Swift Package Manager
        • 兼容 iOS 12+ 系统版本
        """
        instructionsLabel.font = UIFont.systemFont(ofSize: 16)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, instructionsLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])

        return cardView
    }

    // MARK: - Helper Methods

    private func createCardView() -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor.secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.1
        return cardView
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func toggleDoSwift() {
        // 通过检查窗口状态来切换
        if DoSwiftCore.shared.window?.isHidden != false {
            DoSwiftCore.shared.start()
            navigationItem.rightBarButtonItem?.title = "Hide"
        } else {
            DoSwiftCore.shared.stop()
            navigationItem.rightBarButtonItem?.title = "Show"
        }
    }

    @objc private func showDoSwift() {
        DoSwiftCore.shared.start()
        showAlert(title: "DoSwift", message: "悬浮窗已显示")
    }

    @objc private func hideDoSwift() {
        DoSwiftCore.shared.stop()
        showAlert(title: "DoSwift", message: "悬浮窗已隐藏")
    }

    @objc private func addCustomMenuItem() {
        let timestamp = Date().timeIntervalSince1970
        let menuItem = DoSwiftMenuItem(
            identifier: "custom_\(Int(timestamp))",
            title: "动态菜单 \(Int(timestamp))",
            icon: UIImage(systemName: "star.fill")
        ) { _ in
            self.showAlert(title: "动态菜单", message: "这是一个运行时添加的菜单项")
        }

        DoSwiftCore.shared.addMenuItem(menuItem)
        showAlert(title: "成功", message: "已添加新的菜单项到 DoSwift")
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "确定", style: .default))
        present(alertController, animated: true)
    }
}
