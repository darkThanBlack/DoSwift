//
//  DoSwiftHierarchyCells.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/27.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Hierarchy Cell

/// 视图层级展示 Cell
class DoSwiftHierarchyCell: UITableViewCell {

    static let identifier = "DoSwiftHierarchyCell"

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    private let expandIndicator: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private let depthIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadViews(in: contentView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViews(in: contentView)
    }

    // MARK: - Setup

    private func loadViews(in box: UIView) {
        [depthIndicatorView, expandIndicator, titleLabel, subtitleLabel].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            depthIndicatorView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            depthIndicatorView.topAnchor.constraint(equalTo: box.topAnchor),
            depthIndicatorView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            depthIndicatorView.widthAnchor.constraint(equalToConstant: 0), // 动态调整
        ])

        NSLayoutConstraint.activate([
            expandIndicator.leadingAnchor.constraint(equalTo: depthIndicatorView.trailingAnchor),
            expandIndicator.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            expandIndicator.widthAnchor.constraint(equalToConstant: 20),
            expandIndicator.heightAnchor.constraint(equalToConstant: 20),
        ])

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: expandIndicator.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
        ])

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Configuration

    func configure(with node: DoSwiftViewNode) {
        titleLabel.text = node.title
        subtitleLabel.text = node.subtitle

        // 设置层级缩进
        let indentWidth = CGFloat(node.depth * 20)
        if let widthConstraint = depthIndicatorView.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint.constant = indentWidth
        }

        // 设置展开指示器
        if node.children.isEmpty {
            expandIndicator.text = ""
        } else {
            expandIndicator.text = node.isExpanded ? "▼" : "▶"
        }

        // 根据视图类型设置颜色
        if node.view is UIWindow {
            titleLabel.textColor = .systemBlue
        } else if node.view is UIViewController {
            titleLabel.textColor = .systemPurple
        } else {
            titleLabel.textColor = .label
        }
    }
}

// MARK: - Property Cell

/// 属性展示和编辑 Cell
class DoSwiftPropertyCell: UITableViewCell {

    static let identifier = "DoSwiftPropertyCell"

    // MARK: - Properties

    private var property: DoSwiftProperty?
    var valueChangeCallback: ((Any?) -> Void)?

    // MARK: - UI Elements

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isHidden = true
        return switchControl
    }()

    private let stepper: UIStepper = {
        let stepper = UIStepper()
        stepper.isHidden = true
        stepper.minimumValue = -1000
        stepper.maximumValue = 1000
        stepper.stepValue = 1.0
        return stepper
    }()

    private let colorButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        return button
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadViews(in: contentView)
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViews(in: contentView)
        setupActions()
    }

    // MARK: - Setup

    private func loadViews(in box: UIView) {
        [nameLabel, valueLabel, switchControl, stepper, colorButton].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
        ])

        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            valueLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
        ])

        NSLayoutConstraint.activate([
            switchControl.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
        ])

        NSLayoutConstraint.activate([
            stepper.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
        ])

        NSLayoutConstraint.activate([
            colorButton.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            colorButton.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            colorButton.widthAnchor.constraint(equalToConstant: 40),
            colorButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    private func setupActions() {
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        stepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    func configure(with property: DoSwiftProperty) {
        self.property = property
        nameLabel.text = property.name

        // 隐藏所有控件
        valueLabel.isHidden = false
        switchControl.isHidden = true
        stepper.isHidden = true
        colorButton.isHidden = true

        switch property.type {
        case .bool:
            switchControl.isHidden = false
            valueLabel.isHidden = true
            if let boolValue = property.value as? Bool {
                switchControl.setOn(boolValue, animated: false)
            }

        case .number:
            if property.keyPath.contains("alpha") || property.keyPath.contains("cornerRadius") || property.keyPath.contains("borderWidth") {
                stepper.isHidden = false
                valueLabel.isHidden = true
                if let numberValue = property.value as? NSNumber {
                    stepper.value = numberValue.doubleValue
                }
            } else {
                valueLabel.text = formatValue(property.value)
            }

        case .color:
            colorButton.isHidden = false
            valueLabel.isHidden = true
            if let color = property.value as? UIColor {
                colorButton.backgroundColor = color
                colorButton.setTitle("", for: .normal)
            } else {
                colorButton.backgroundColor = .systemGray6
                colorButton.setTitle("无", for: .normal)
            }

        default:
            valueLabel.text = formatValue(property.value)
        }

        // 只读属性禁用交互
        let isEditable = property.type != .readonly && !property.keyPath.isEmpty
        switchControl.isEnabled = isEditable
        stepper.isEnabled = isEditable
        colorButton.isEnabled = isEditable
    }

    // MARK: - Actions

    @objc private func switchValueChanged() {
        valueChangeCallback?(switchControl.isOn)
    }

    @objc private func stepperValueChanged() {
        valueChangeCallback?(NSNumber(value: stepper.value))
    }

    @objc private func colorButtonTapped() {
        // 简单的颜色选择器
        let alert = UIAlertController(title: "选择颜色", message: nil, preferredStyle: .actionSheet)

        let colors: [(String, UIColor)] = [
            ("红色", .systemRed),
            ("绿色", .systemGreen),
            ("蓝色", .systemBlue),
            ("黄色", .systemYellow),
            ("紫色", .systemPurple),
            ("橙色", .systemOrange),
            ("黑色", .black),
            ("白色", .white),
            ("透明", .clear)
        ]

        for (name, color) in colors {
            alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                self.valueChangeCallback?(color)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let viewController = findViewController() {
            viewController.present(alert, animated: true)
        }
    }

    // MARK: - Helper Methods

    private func formatValue(_ value: Any?) -> String {
        if let value = value {
            if let rectValue = value as? NSValue, rectValue.responds(to: #selector(getter: NSValue.cgRectValue)) {
                let rect = rectValue.cgRectValue
                return String(format: "%.1f, %.1f, %.1f, %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
            } else if let pointValue = value as? NSValue, pointValue.responds(to: #selector(getter: NSValue.cgPointValue)) {
                let point = pointValue.cgPointValue
                return String(format: "%.1f, %.1f", point.x, point.y)
            } else if let numberValue = value as? NSNumber {
                return String(format: "%.2f", numberValue.doubleValue)
            } else {
                return String(describing: value)
            }
        }
        return "nil"
    }

    private func findViewController() -> UIViewController? {
        var responder = next
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

// MARK: - Property Header View

/// 属性分类头部视图
class DoSwiftPropertyHeaderView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let arrowLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "▶"
        return label
    }()

    private var tapCallback: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViews(in: self)
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViews(in: self)
        setupTapGesture()
    }

    private func loadViews(in box: UIView) {
        backgroundColor = .secondarySystemBackground

        [iconImageView, titleLabel, arrowLabel].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
        ])

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            arrowLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            arrowLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        addGestureRecognizer(tapGesture)
    }

    @objc private func headerTapped() {
        tapCallback?()
    }

    func configure(with category: DoSwiftPropertyCategory, tapCallback: @escaping () -> Void) {
        titleLabel.text = category.name
        iconImageView.image = category.icon
        arrowLabel.text = category.isExpanded ? "▼" : "▶"
        self.tapCallback = tapCallback
    }
}
