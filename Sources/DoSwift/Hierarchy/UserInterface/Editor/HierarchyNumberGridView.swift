//
//  HierarchyNumberGridView.swift
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

    final class HierarchyNumberGridView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)?

        private let fields: [DO.HierarchyNumberFieldView]
        private let compose: ([Double]) -> DO.ValueKind

        init(labels: [String], values: [Double], compose: @escaping ([Double]) -> DO.ValueKind) {
            self.compose = compose
            self.fields = values.map {
                DO.HierarchyNumberFieldView(isInteger: false, step: 1, value: $0, prominent: false)
            }
            super.init(frame: .zero)
            setupSubviews(labels: labels)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard let numbers = currentValues() else { return nil }
            return compose(numbers)
        }

        private func setupSubviews(labels: [String]) {
            let rows: [UIView] = zip(labels, fields).map { label, field in
                let name = DO.HierarchyEditorStyle.makeLabel(label)
                name.setContentHuggingPriority(.required, for: .horizontal)
                name.setContentCompressionResistancePriority(.required, for: .horizontal)

                let row = UIStackView(arrangedSubviews: [name, field])
                row.axis = .horizontal
                row.alignment = .center
                row.spacing = 12

                name.widthAnchor.constraint(equalToConstant: 64).isActive = true
                return row
            }

            let stack = UIStackView(arrangedSubviews: rows)
            stack.axis = .vertical
            stack.spacing = DO.HierarchyEditorStyle.rowGap

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            for field in fields {
                field.onValueChanged = { [weak self] in self?.changed() }
                field.onValidityChange = { [weak self] _ in self?.changed() }
            }
        }

        private func currentValues() -> [Double]? {
            var numbers: [Double] = []
            for field in fields {
                guard case let .double(number)? = field.readValue() else { return nil }
                numbers.append(number)
            }
            return numbers
        }

        private func changed() {
            let values = currentValues()
            onValidityChange?(values != nil)
        }

    }
}
