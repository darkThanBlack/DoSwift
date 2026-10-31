//
//  HierarchyMultilineTextView.swift
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

    final class HierarchyMultilineTextView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)?

        private let originalText: String
        private var isEdited = false

        private static let height: CGFloat = 280

        init(text: String) {
            self.originalText = text
            super.init(frame: .zero)
            textView.text = text
            setupSubviews()
            updateMeta()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            .text(isEdited ? (textView.text ?? "") : originalText)
        }

        private lazy var textView: UITextView = {
            let view = UITextView()
            view.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
            view.backgroundColor = DO.HierarchyEditorStyle.fieldBackground
            view.layer.cornerRadius = DO.HierarchyEditorStyle.fieldRadius
            view.layer.masksToBounds = true
            view.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
            view.delegate = self
            view.isScrollEnabled = true

            DO.HierarchyEditorStyle.disableSmartInput(view)
            return view
        }()

        private lazy var metaLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .secondaryLabel
            return label
        }()

        private func setupSubviews() {
            let stack = UIStackView(arrangedSubviews: [textView, metaLabel])
            stack.axis = .vertical
            stack.spacing = 8

            metaLabel.setContentHuggingPriority(.required, for: .vertical)

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textView.heightAnchor.constraint(equalToConstant: Self.height),
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private func updateMeta() {
            let text = textView.text ?? ""
            let lines = text.isEmpty ? 0 : text.components(separatedBy: .newlines).count
            metaLabel.text = "\(text.count) 字符 · \(lines) 行"
        }
    }

}

extension DO.HierarchyMultilineTextView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        isEdited = true
        updateMeta()
    }
}
