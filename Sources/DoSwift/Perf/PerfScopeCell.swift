//
//  PerfScopeCell.swift
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

    final class PerfScopeCell: UITableViewCell {

        var onSelectAll: (() -> Void)?

        private static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()

        func configure(range: ClosedRange<TimeInterval>, isFull: Bool, now: TimeInterval) {
            rangeLabel.text = "\(Self.text(range.lowerBound, now: now)) – \(Self.text(range.upperBound, now: now))"
            allButton.isEnabled = !isFull
            allButton.alpha = isFull ? 0.35 : 1
        }

        private static func text(_ time: TimeInterval, now: TimeInterval) -> String {
            return formatter.string(from: Date(timeIntervalSinceNow: time - now))
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            selectionStyle = .none
            let row = UIStackView(arrangedSubviews: [rangeLabel, allButton])
            row.axis = .horizontal
            row.alignment = .center
            row.distribution = .fill
            rangeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            rangeLabel.translatesAutoresizingMaskIntoConstraints = false
            row.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private lazy var rangeLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            label.textColor = .label
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            return label
        }()

        private lazy var allButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("全部", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.addTarget(self, action: #selector(handleSelectAll), for: .touchUpInside)
            return button
        }()

        @objc private func handleSelectAll() {
            onSelectAll?()
        }
    }
}
