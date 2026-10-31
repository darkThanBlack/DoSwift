//
//  HierarchyColorPanelView.swift
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

    final class HierarchyColorPanelView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)?

        private var pending: UIColor

        init(color: UIColor) {
            self.pending = color
            super.init(frame: .zero)
            setupSubviews()

            field.text = color.hierarchy_editableText
            alphaSlider.value = Float(color.hierarchy_alpha)
            refresh()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            syncPendingFromField() ? .color(pending) : nil
        }

        private lazy var swatch: UIView = {
            let view = UIView()
            view.layer.cornerRadius = DO.HierarchyEditorStyle.fieldRadius
            view.layer.masksToBounds = true
            view.layer.borderWidth = 1 / UIScreen.main.scale
            view.layer.borderColor = UIColor.separator.cgColor
            view.heightAnchor.constraint(equalToConstant: 64).isActive = true
            return view
        }()

        private lazy var field: UITextField = {
            let field = UITextField()
            field.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
            field.backgroundColor = DO.HierarchyEditorStyle.fieldBackground
            field.layer.cornerRadius = DO.HierarchyEditorStyle.fieldRadius
            field.layer.masksToBounds = true
            field.borderStyle = .none
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
            field.leftViewMode = .always
            field.heightAnchor.constraint(equalToConstant: 44).isActive = true

            DO.HierarchyEditorStyle.disableSmartInput(field)
            field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
            return field
        }()

        private lazy var alphaSlider: UISlider = {
            let slider = UISlider()
            slider.minimumValue = 0
            slider.maximumValue = 1
            slider.isContinuous = false   // 松手才回报一次，途中不必反复改值
            slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
            return slider
        }()

        private lazy var hintLabel: UILabel = {
            let label = DO.HierarchyEditorStyle.makeLabel("也收 r,g,b,a · #RRGGBBAA")
            label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            label.textColor = .tertiaryLabel
            return label
        }()

        private func setupSubviews() {
            let alphaLabel = DO.HierarchyEditorStyle.makeLabel("alpha")
            let alphaRow = UIStackView(arrangedSubviews: [alphaLabel, alphaSlider])
            alphaRow.axis = .horizontal
            alphaRow.alignment = .center
            alphaRow.spacing = 12
            alphaLabel.widthAnchor.constraint(equalToConstant: 64).isActive = true

            let stack = UIStackView(arrangedSubviews: [swatch, field, hintLabel, alphaRow])
            stack.axis = .vertical
            stack.spacing = 10
            stack.setCustomSpacing(4, after: field)

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        @objc private func fieldChanged() {
            guard syncPendingFromField() else {
                onValidityChange?(false)
                return
            }
            alphaSlider.value = Float(pending.hierarchy_alpha)
            refresh()
            onValidityChange?(true)
        }

        @objc private func sliderChanged() {
            pending = pending.withAlphaComponent(CGFloat(alphaSlider.value))
            field.text = pending.hierarchy_editableText
            refresh()
        }

        private func syncPendingFromField() -> Bool {
            guard let text = field.text, let parsed = UIColor.hierarchy_color(from: text) else { return false }
            pending = parsed
            return true
        }

        private func refresh() {
            swatch.backgroundColor = pending
        }
    }
}
