//
//  ConsoleLineCell.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// One log block: meta line, message, hairline. Meta is not inline because a wrapped message
    /// then has no visible boundary; the rule restores it without bringing back the card look.
    @objc(DOConsoleLineCell)
    final class ConsoleLineCell: UITableViewCell, DO.SectionCell {

        weak var sectionDelegate: DO.SectionCellDelegate?

        private enum Metrics {
            static let vertical: CGFloat = 3
            static let horizontal: CGFloat = 10
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            backgroundColor = .systemBackground
            selectionStyle = .default

            stack.translatesAutoresizingMaskIntoConstraints = false
            separator.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(stack)
            contentView.addSubview(separator)

            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.vertical),
                stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.horizontal),
                stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.horizontal),

                separator.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: Metrics.vertical),
                separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.horizontal),
                separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.horizontal),
                separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
                separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(_ line: DO.ConsoleLine) {
            metaLabel.text = "\(line.timeText)  \(line.metaTag)"
            messageLabel.text = line.text
            messageLabel.textColor = Self.color(for: line.level)
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            guard selected else { return }
            sectionDelegate?.sectionCellDidTrigger(self)
        }

        private static func color(for level: DO.ConsoleLine.Level?) -> UIColor {
            guard let level = level else { return .label }

            switch level {
            case .debug:         return .secondaryLabel
            case .error, .fault: return .systemRed
            default:             return .label
            }
        }

        private lazy var stack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [metaLabel, messageLabel])
            stack.axis = .vertical
            stack.alignment = .fill
            stack.spacing = 2
            return stack
        }()

        private lazy var metaLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 1
            return label
        }()

        private lazy var messageLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .label
            label.numberOfLines = 0
            return label
        }()

        private lazy var separator: UIView = {
            let view = UIView()
            view.backgroundColor = .separator
            return view
        }()
    }
}
