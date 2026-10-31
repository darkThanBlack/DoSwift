//
//  HierarchyInfoView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    protocol HierarchyInfoViewDelegate: AnyObject {
        func hierarchyInfoViewDidSelectParent(_ view: DO.HierarchyInfoView)
        func hierarchyInfoViewDidSelectSubview(_ view: DO.HierarchyInfoView)
        func hierarchyInfoViewDidSelectMoreInfo(_ view: DO.HierarchyInfoView)
        func hierarchyInfoViewDidSelectSetting(_ view: DO.HierarchyInfoView)
        func hierarchyInfoViewDidSelectClose(_ view: DO.HierarchyInfoView)
    }

    final class HierarchyInfoView: UIView {

        weak var delegate: DO.HierarchyInfoViewDelegate?

        private(set) weak var selectedView: UIView?

        func updateRulerInfo(_ text: String?) {
            rulerRow.value = text
        }

        func updatePixelColor(_ description: String?) {
            pixelColorRow.value = description
        }

        func updateSelectedView(_ view: UIView?) {
            guard let view = view, view !== selectedView else { return }
            selectedView = view

            apply("class", of: view, to: nameRow)
            apply("frame", of: view, to: frameRow)
            apply("backgroundColor", of: view, to: backgroundColorRow)
            apply("textColor", of: view, to: textColorRow)
            apply("font", of: view, to: fontRow)
            apply("tag", of: view, to: tagRow)

            parentButton.isEnabled = view.superview != nil
            subviewsButton.isEnabled = !view.subviews.isEmpty
            moreButton.isEnabled = true
        }

        private func apply(_ key: String, of view: UIView, to row: HierarchyInfoRowView) {
            let model = DO.HierarchyPropertyEngine.shared.cellModel(for: view, key: key)
            row.key = model?.title
            row.value = model?.detailTitle
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupSubviews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupSubviews(in box: UIView) {
            backgroundColor = .systemBackground
            layer.cornerRadius = 12.0
            layer.masksToBounds = true
            layer.borderWidth = 1.0
            layer.borderColor = UIColor.separator.cgColor

            addSubview(rootStack)

            [rootStack, closeButton, settingButton, actionStack].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            NSLayoutConstraint.activate([
                rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
                rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

                closeButton.widthAnchor.constraint(equalToConstant: 28),
                closeButton.heightAnchor.constraint(equalToConstant: 28),

                settingButton.widthAnchor.constraint(equalToConstant: 28),
                settingButton.heightAnchor.constraint(equalToConstant: 28),

                actionStack.heightAnchor.constraint(equalToConstant: 34),
            ])
        }

        @objc private func parentTapped() {
            delegate?.hierarchyInfoViewDidSelectParent(self)
        }

        @objc private func subviewTapped() {
            delegate?.hierarchyInfoViewDidSelectSubview(self)
        }

        @objc private func moreInfoTapped() {
            delegate?.hierarchyInfoViewDidSelectMoreInfo(self)
        }

        @objc private func settingTapped() {
            delegate?.hierarchyInfoViewDidSelectSetting(self)
        }

        @objc private func closeTapped() {
            delegate?.hierarchyInfoViewDidSelectClose(self)
        }

        private lazy var rootStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [headerStack, infoStack, actionStack])
            stack.axis = .vertical
            stack.spacing = 10
            return stack
        }()

        private lazy var headerStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [titleLabel, settingButton, closeButton])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 8
            return stack
        }()

        private lazy var infoStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [
                rulerRow, pixelColorRow, nameRow,
                frameRow, backgroundColorRow, textColorRow, fontRow, tagRow,
            ])
            stack.axis = .vertical
            stack.spacing = 6
            return stack
        }()

        private lazy var actionStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [parentButton, subviewsButton, moreButton])
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 8
            return stack
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = "UI Hierarchy"
            label.font = .boldSystemFont(ofSize: 15)
            label.textColor = .label
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            return label
        }()

        private lazy var settingButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "gear"), for: .normal)
            button.tintColor = .secondaryLabel
            button.addTarget(self, action: #selector(settingTapped), for: .touchUpInside)
            return button
        }()

        private lazy var closeButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            button.tintColor = .secondaryLabel
            button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            return button
        }()

        private lazy var rulerRow = HierarchyInfoRowView(key: "Position:")
        private lazy var nameRow = HierarchyInfoRowView(key: "Name:")
        private lazy var pixelColorRow = HierarchyInfoRowView(key: "Pixel:")
        private lazy var frameRow = HierarchyInfoRowView(key: "Frame:")
        private lazy var backgroundColorRow = HierarchyInfoRowView(key: "Background:")
        private lazy var textColorRow = HierarchyInfoRowView(key: "Text Color:")
        private lazy var fontRow = HierarchyInfoRowView(key: "Font:")
        private lazy var tagRow = HierarchyInfoRowView(key: "Tag:")

        private lazy var parentButton = makeActionButton(
            title: "Parents", symbol: "arrow.up", action: #selector(parentTapped)
        )
        private lazy var subviewsButton = makeActionButton(
            title: "Childs", symbol: "arrow.down", action: #selector(subviewTapped)
        )
        private lazy var moreButton = makeActionButton(
            title: "More", symbol: "info.circle", action: #selector(moreInfoTapped)
        )

        private func makeActionButton(title: String, symbol: String, action: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.setTitleColor(.label, for: .normal)
            button.setTitleColor(.tertiaryLabel, for: .disabled)
            button.setImage(UIImage(systemName: symbol), for: .normal)
            button.tintColor = .secondaryLabel
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
            button.addTarget(self, action: action, for: .touchUpInside)
            button.isEnabled = false
            return button
        }
    }

    private final class HierarchyInfoRowView: UIView {

        var key: String? {
            get { keyLabel.text }
            set { keyLabel.text = newValue }
        }

        var value: String? {
            get { valueLabel.text }
            set {
                guard valueLabel.text != newValue else { return }
                valueLabel.text = newValue
                isHidden = (newValue == nil)
            }
        }

        init(key: String) {
            super.init(frame: .zero)

            keyLabel.text = key

            setupSubviews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupSubviews(in box: UIView) {
            keyLabel.setContentHuggingPriority(.required, for: .horizontal)
            keyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            layer.cornerRadius = 4.0

            addGestureRecognizer(tapGesture)
            addSubview(stacks)

            [stacks].forEach({
                $0.translatesAutoresizingMaskIntoConstraints = false
            })
            NSLayoutConstraint.activate([
                stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 0.0),
                stacks.leftAnchor.constraint(equalTo: box.leftAnchor, constant: 0.0),
                stacks.rightAnchor.constraint(equalTo: box.rightAnchor, constant: 0.0),
                stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: 0.0),
            ])
        }

        private lazy var stacks: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [keyLabel, valueLabel, UIView()])
            stacks.axis = .horizontal
            stacks.alignment = .center
            stacks.distribution = .fill
            stacks.spacing = 4.0
            return stacks
        }()

        @objc private func handleTap() {
            guard let text = valueLabel.text, !text.isEmpty else { return }

            UIPasteboard.general.string = text

            backgroundColor = .clear
            UIView.animate(withDuration: 0.12) {
                self.backgroundColor = .tertiarySystemFill
            } completion: { _ in
                UIView.animate(withDuration: 0.22) {
                    self.backgroundColor = .clear
                }
            }
        }

        private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))

        private lazy var keyLabel: UILabel = {
            let label = UILabel()
            label.font = .boldSystemFont(ofSize: 13)
            label.textColor = .label
            return label
        }()

        private lazy var valueLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 13)
            label.textColor = .label
            label.numberOfLines = 0
            return label
        }()

    }
}
