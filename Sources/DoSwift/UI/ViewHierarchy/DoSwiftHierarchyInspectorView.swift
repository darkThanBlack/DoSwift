//
//  DoSwiftHierarchyInspectorView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// 浮窗式 UI 结构属性检查器
class DoSwiftHierarchyInspectorView: UIView {

    // MARK: - Properties

    weak var selectedView: UIView? {
        didSet {
            updateInspectorInfo()
        }
    }

    var onParentViewsTapped: (() -> Void)?
    var onSubviewsTapped: (() -> Void)?
    var onMoreInfoTapped: (() -> Void)?

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.text = "UI Inspector"
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let frameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        return label
    }()

    private let backgroundLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()

    private let textColorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()

    private let fontLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()

    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 1
        return stack
    }()

    private let parentViewsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Parent Views", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return button
    }()

    private let subviewsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Subviews", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return button
    }()

    private let moreInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("More Info", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupActions()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(containerView)

        [titleLabel, nameLabel, frameLabel, backgroundLabel, textColorLabel, fontLabel, buttonStackView].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [parentViewsButton, subviewsButton, moreInfoButton].forEach {
            buttonStackView.addArrangedSubview($0)
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Container view
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 180),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Name
            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Frame
            frameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            frameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            frameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Background
            backgroundLabel.topAnchor.constraint(equalTo: frameLabel.bottomAnchor, constant: 4),
            backgroundLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            backgroundLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Text Color
            textColorLabel.topAnchor.constraint(equalTo: backgroundLabel.bottomAnchor, constant: 4),
            textColorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textColorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Font
            fontLabel.topAnchor.constraint(equalTo: textColorLabel.bottomAnchor, constant: 4),
            fontLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            fontLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Button stack
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActions() {
        parentViewsButton.addTarget(self, action: #selector(parentViewsButtonTapped), for: .touchUpInside)
        subviewsButton.addTarget(self, action: #selector(subviewsButtonTapped), for: .touchUpInside)
        moreInfoButton.addTarget(self, action: #selector(moreInfoButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func parentViewsButtonTapped() {
        onParentViewsTapped?()
    }

    @objc private func subviewsButtonTapped() {
        onSubviewsTapped?()
    }

    @objc private func moreInfoButtonTapped() {
        onMoreInfoTapped?()
    }

    // MARK: - Update Methods

    private func updateInspectorInfo() {
        guard let view = selectedView else {
            nameLabel.text = "No Selection"
            frameLabel.text = ""
            backgroundLabel.text = ""
            textColorLabel.text = ""
            fontLabel.text = ""
            return
        }

        // Name
        nameLabel.text = "Name: \(String(describing: type(of: view)))"

        // Frame
        let frame = view.frame
        frameLabel.text = "Frame: {{\(String(format: "%.2f", frame.origin.x)), \(String(format: "%.2f", frame.origin.y))}, {\(String(format: "%.2f", frame.size.width)), \(String(format: "%.2f", frame.size.height))}}"

        // Background Color
        if let backgroundColor = view.backgroundColor {
            if backgroundColor == .clear {
                backgroundLabel.text = "Background: Clear Color"
            } else {
                backgroundLabel.text = "Background: \(colorDescription(backgroundColor))"
            }
        } else {
            backgroundLabel.text = "Background: nil"
        }

        // Text Color & Font (if it's a UILabel)
        if let label = view as? UILabel {
            if let textColor = label.textColor {
                textColorLabel.text = "Text Color: \(colorDescription(textColor))"
            } else {
                textColorLabel.text = "Text Color: nil"
            }

            if let font = label.font {
                fontLabel.text = "Font: \(String(format: "%.2f", font.pointSize))"
            } else {
                fontLabel.text = "Font: nil"
            }
        } else {
            textColorLabel.text = ""
            fontLabel.text = ""
        }
    }

    private func colorDescription(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let r = Int(red * 255)
            let g = Int(green * 255)
            let b = Int(blue * 255)
            return String(format: "#%02X%02X%02X", r, g, b)
        }

        return "Unknown"
    }

    // MARK: - Public Methods

    func show(in parentView: UIView) {
        guard superview == nil else { return }

        parentView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parentView.topAnchor),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])

        // 入场动画
        containerView.transform = CGAffineTransform(translationX: 0, y: 200)
        containerView.alpha = 0

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        })
    }

    func hide() {
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 200)
            self.containerView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}