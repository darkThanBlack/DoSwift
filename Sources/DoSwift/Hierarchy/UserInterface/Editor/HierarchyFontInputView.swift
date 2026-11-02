//
//  HierarchyFontInputView.swift
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

    @objc(DOHierarchyFontInputView)
    final class HierarchyFontInputView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)? {
            didSet { onValidityChange?(readValue() != nil) }
        }

        private let originalFont: UIFont
        private lazy var field = DO.HierarchyNumberFieldView(isInteger: false, step: 0.5,
                                                          value: Double(originalFont.pointSize))

        init(font: UIFont) {
            self.originalFont = font
            super.init(frame: .zero)
            setupSubviews()
            refreshPreview()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            guard case let .double(size)? = field.readValue() else { return nil }
            return .font(originalFont.withSize(CGFloat(size)))
        }

        private lazy var preview: UILabel = {
            let label = UILabel()
            label.text = "The quick brown fox 字体预览"
            label.numberOfLines = 2
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            return label
        }()

        private func setupSubviews() {
            let stack = UIStackView(arrangedSubviews: [preview, field])
            stack.axis = .vertical
            stack.spacing = 14

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            field.onValueChanged = { [weak self] in self?.refreshPreview() }
            field.onValidityChange = { [weak self] isValid in self?.onValidityChange?(isValid) }
        }

        private func refreshPreview() {
            guard case let .double(size)? = field.readValue(), size > 0 else { return }
            preview.font = originalFont.withSize(CGFloat(size))
        }
    }
}
