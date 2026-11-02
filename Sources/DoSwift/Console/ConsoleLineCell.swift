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

    /// One block of log output, laid out to read as a slice of one long text view.
    ///
    /// The timestamp and source sit inline at the start of the text rather than on their own
    /// row: a separate meta line doubles the height of every entry and breaks the wall of text
    /// the console is trying to be.
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

            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.vertical),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Metrics.vertical),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.horizontal),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.horizontal),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(_ line: DO.ConsoleLine) {
            label.attributedText = Self.text(for: line)
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            guard selected else { return }
            sectionDelegate?.sectionCellDidTrigger(self)
        }

        private static func text(for line: DO.ConsoleLine) -> NSAttributedString {
            let result = NSMutableAttributedString()

            let meta = "\(line.timeText)  \(line.source.shortTitle)  "
            result.append(NSAttributedString(string: meta, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel,
            ]))

            result.append(NSAttributedString(string: line.text, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: color(for: line.level),
            ]))

            return result
        }

        private static func color(for level: DO.ConsoleLine.Level?) -> UIColor {
            guard let level = level else { return .label }

            switch level {
            case .debug:         return .secondaryLabel
            case .error, .fault: return .systemRed
            default:             return .label
            }
        }

        private let label: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            return label
        }()
    }
}
