//
//  HierarchyNumberFieldView.swift
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

    final class HierarchyNumberFieldView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)? {
            didSet { onValidityChange?(readValue() != nil) }
        }

        var onValueChanged: (() -> Void)?

        private let isInteger: Bool

        private let originalValue: Double
        private var isEdited = false

        init(isInteger: Bool, step: Double, value: Double, prominent: Bool = true) {
            self.isInteger = isInteger
            self.originalValue = value
            super.init(frame: .zero)

            field.text = Self.text(for: value, isInteger: isInteger)
            field.font = prominent ? DO.HierarchyEditorStyle.prominentValueFont
                                   : DO.HierarchyEditorStyle.valueFont
            fieldHeight.constant = prominent ? 60 : 40

            stepper.minimumValue = -Self.stepperBound
            stepper.maximumValue = Self.stepperBound
            stepper.stepValue = step
            stepper.value = value

            setupSubviews()
            fieldHeight.isActive = true
            updateValidity()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard let number = currentValue() else { return nil }
            return isInteger ? .int(Int(number)) : .double(number)
        }

        private lazy var fieldHeight = field.heightAnchor.constraint(equalToConstant: 40)

        private lazy var field: UITextField = {
            let field = UITextField()
            field.font = DO.HierarchyEditorStyle.valueFont
            field.textAlignment = .center
            field.backgroundColor = DO.HierarchyEditorStyle.fieldBackground
            field.layer.cornerRadius = DO.HierarchyEditorStyle.fieldRadius
            field.layer.masksToBounds = true
            field.borderStyle = .none

            field.keyboardType = isInteger ? .numbersAndPunctuation : .decimalPad
            DO.HierarchyEditorStyle.disableSmartInput(field)
            field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
            return field
        }()

        private lazy var stepper: UIStepper = {
            let stepper = UIStepper()
            stepper.autorepeat = true
            stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
            return stepper
        }()

        private static let stepperBound = 1e15

        private func setupSubviews() {
            let stack = UIStackView(arrangedSubviews: [field, stepper])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 12

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
            isEdited = true
            if let number = parsedNumber() { stepper.value = number }
            updateValidity()
            onValueChanged?()
        }

        @objc private func stepperChanged() {
            isEdited = true
            field.text = Self.text(for: stepper.value, isInteger: isInteger)
            updateValidity()
            onValueChanged?()
        }

        private func parsedNumber() -> Double? {
            guard let text = field.text, !text.isEmpty else { return nil }
            return isInteger ? Int(text).map(Double.init) : Double(text)
        }

        private func updateValidity() {
            onValidityChange?(parsedNumber() != nil)
        }

        private func currentValue() -> Double? {
            guard parsedNumber() != nil else { return nil }
            return isEdited ? parsedNumber() : originalValue
        }

        private static func text(for value: Double, isInteger: Bool) -> String {
            isInteger ? "\(Int(value))" : DO.HierarchyFormatterTool.format(NSNumber(value: value))
        }
    }
}
