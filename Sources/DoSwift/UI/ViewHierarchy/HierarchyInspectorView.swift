//
//  HierarchyInspectorView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol HierarchyInspectorViewDelegate: AnyObject {
    func inspectorViewDidRequestClose(_ inspectorView: HierarchyInspectorView)
    func inspectorViewDidRequestMoreInfo(_ inspectorView: HierarchyInspectorView)
    func inspectorViewDidRequestParentViews(_ inspectorView: HierarchyInspectorView)
    func inspectorViewDidRequestSubviews(_ inspectorView: HierarchyInspectorView)
}

/// 浮窗式 UI 结构属性检查器 - 纯 UI 展示
class HierarchyInspectorView: UIView {

    // MARK: - Properties

    weak var delegate: HierarchyInspectorViewDelegate?

    private var selectedView: UIView?
    private var currentDragLocation: CGPoint = .zero

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

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("关闭", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        return button
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()

    private let coordinateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.text = "Position: (0, 0)"
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
        button.setTitle("父视图", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return button
    }()

    private let subviewsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("子视图", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return button
    }()

    private let moreInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("详细信息", for: .normal)
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

        [titleLabel, closeButton, nameLabel, coordinateLabel, frameLabel, backgroundLabel, textColorLabel, fontLabel, buttonStackView].forEach {
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
            containerView.heightAnchor.constraint(equalToConstant: 200),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            // Close Button
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            // Name
            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Coordinate
            coordinateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            coordinateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            coordinateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Frame
            frameLabel.topAnchor.constraint(equalTo: coordinateLabel.bottomAnchor, constant: 4),
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
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func parentViewsButtonTapped() {
        delegate?.inspectorViewDidRequestParentViews(self)
    }

    @objc private func subviewsButtonTapped() {
        delegate?.inspectorViewDidRequestSubviews(self)
    }

    @objc private func moreInfoButtonTapped() {
        delegate?.inspectorViewDidRequestMoreInfo(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.inspectorViewDidRequestClose(self)
    }

    // MARK: - Public Methods

    func updateSelectedView(_ view: UIView) {
        selectedView = view
        updateInspectorInfo()
    }

    func updateDragLocation(_ location: CGPoint) {
        currentDragLocation = location
        updateCoordinateDisplay()
    }

    // MARK: - Update Methods

    private func updateInspectorInfo() {
        updateCoordinateDisplay()

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
            if backgroundColor == UIColor.clear {
                backgroundLabel.text = "Background: Clear Color"
            } else {
                backgroundLabel.text = "Background: \(hexStringFromColor(backgroundColor))"
            }
        } else {
            backgroundLabel.text = "Background: nil"
        }

        // Text Color and Font (for UILabel)
        if let label = view as? UILabel {
            if let textColor = label.textColor {
                textColorLabel.text = "Text Color: \(hexStringFromColor(textColor))"
            } else {
                textColorLabel.text = "Text Color: nil"
            }

            if let font = label.font {
                fontLabel.text = "Font: \(font.fontName) \(String(format: "%.1f", font.pointSize))pt"
            } else {
                fontLabel.text = "Font: nil"
            }
        } else {
            textColorLabel.text = ""
            fontLabel.text = ""
        }
    }

    private func updateCoordinateDisplay() {
        coordinateLabel.text = "Position: (\(String(format: "%.0f", currentDragLocation.x)), \(String(format: "%.0f", currentDragLocation.y)))"
    }

    private func hexStringFromColor(_ color: UIColor) -> String {
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}