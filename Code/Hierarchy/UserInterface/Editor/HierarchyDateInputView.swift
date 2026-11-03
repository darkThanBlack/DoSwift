//
//  HierarchyDateInputView.swift
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

    @objc(DOHierarchyDateInputView)
    final class HierarchyDateInputView: UIView, DO.HierarchyValueInput {

        var onValidityChange: ((Bool) -> Void)?

        private let originalDate: Date
        private var isEdited = false

        init(date: Date) {
            self.originalDate = date
            super.init(frame: .zero)
            picker.date = date
            setupSubviews()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func readValue() -> DO.ValueKind? {
            .date(isEdited ? picker.date : originalDate)
        }

        private lazy var picker: UIDatePicker = {
            let picker = UIDatePicker()
            picker.datePickerMode = .dateAndTime

            if #available(iOS 13.4, *) {
                picker.preferredDatePickerStyle = .wheels
            }
            picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
            return picker
        }()

        private func setupSubviews() {
            let chips = UIStackView(arrangedSubviews: [
                makeChip("现在", offset: 0),
                makeChip("+1 天", offset: 86_400),
                makeChip("+1 小时", offset: 3_600),
            ])
            chips.axis = .horizontal
            chips.spacing = 8

            let stack = UIStackView(arrangedSubviews: [picker, chips])
            stack.axis = .vertical
            stack.spacing = 12
            stack.alignment = .fill

            addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private func makeChip(_ title: String, offset: TimeInterval) -> UIButton {
            if #available(iOS 15.0, *) {
                var configuration = UIButton.Configuration.gray()
                configuration.title = title
                configuration.cornerStyle = .capsule
                configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
                return UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
                    self?.applyOffset(offset)
                })
            }

            let legacy = UIButton(type: .system)
            legacy.setTitle(title, for: .normal)
            legacy.titleLabel?.font = .systemFont(ofSize: 14)
            legacy.backgroundColor = .tertiarySystemFill
            legacy.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            legacy.layer.cornerRadius = 14
            legacy.tag = Int(offset)
            legacy.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            return legacy
        }

        private func applyOffset(_ offset: TimeInterval) {
            picker.setDate(Date().addingTimeInterval(offset), animated: true)
            pickerChanged()
        }

        @objc private func chipTapped(_ sender: UIButton) {
            applyOffset(TimeInterval(sender.tag))
        }

        @objc private func pickerChanged() {
            isEdited = true
            onValidityChange?(true)
        }
    }
}
