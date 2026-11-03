//
//  ToggleCell.swift
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

    protocol ToggleCellDataSource {

        var title: String { get }

        var detail: String { get }

        var isOn: Bool { get }
    }

    @objc(DOToggleCell)
    final class ToggleCell: UITableViewCell, DO.SectionCell {

        weak var sectionDelegate: DO.SectionCellDelegate?

        var isOn: Bool {
            swit.isOn
        }

        func update(_ dataSource: DO.ToggleCellDataSource?) {
            update(
                title: dataSource?.title,
                detail: dataSource?.detail,
                isOn: dataSource?.isOn ?? false
            )
        }

        func update(title: String? = nil, detail: String? = nil, isOn: Bool = false) {
            titleLabel.text = title
            detailLabel.text = detail

            swit.setOn(isOn, animated: false)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            selectionStyle = .none
            loadViews(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func loadViews(in box: UIView) {
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
            swit.setContentHuggingPriority(.required, for: .horizontal)
            swit.setContentCompressionResistancePriority(.required, for: .horizontal)

            stacks.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(stacks)

            NSLayoutConstraint.activate([
                stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
                stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
                stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
                stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
            ])
        }

        @objc private func switchChanged(_ sender: UISwitch) {
            sectionDelegate?.sectionCellDidTrigger(self)
        }

        private lazy var stacks: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [textStack, swit])
            stacks.axis = .horizontal
            stacks.alignment = .center
            stacks.spacing = 8
            return stacks
        }()

        private lazy var textStack: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
            stacks.axis = .vertical
            stacks.alignment = .leading
            stacks.spacing = 2.0
            return stacks
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .label
            label.numberOfLines = 0
            return label
        }()

        private lazy var detailLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            return label
        }()

        private lazy var swit: UISwitch = {
            let swit = UISwitch()
            swit.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            return swit
        }()
    }
}
