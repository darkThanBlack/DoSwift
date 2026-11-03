//
//  TrendHeaderView.swift
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

    @objc(DOTrendHeaderView)
    final class TrendHeaderView: UIView {

        func render(_ chart: DO.TrendChart?, now: TimeInterval) {
            titleLabel.text = chart?.title
            unitLabel.text = chart?.unit
            valueLabel.text = chart?.valueText(at: now)

            let alarming = chart?.isAlarming(at: now) ?? false
            valueLabel.textColor = alarming ? .systemRed : .label
            titleLabel.textColor = alarming ? .systemRed : .secondaryLabel
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            loadViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func loadViews() {
            titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            valueStack.setContentHuggingPriority(.required, for: .horizontal)
            valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            unitLabel.setContentHuggingPriority(.required, for: .horizontal)
            unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            addSubview(topRow)
            topRow.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                topRow.topAnchor.constraint(equalTo: topAnchor),
                topRow.leadingAnchor.constraint(equalTo: leadingAnchor),
                topRow.trailingAnchor.constraint(equalTo: trailingAnchor),
                topRow.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        private lazy var topRow: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueStack])
            stacks.axis = .horizontal
            stacks.alignment = .lastBaseline
            stacks.distribution = .fill
            return stacks
        }()

        private lazy var valueStack: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
            stacks.axis = .horizontal
            stacks.alignment = .lastBaseline
            stacks.spacing = 4
            return stacks
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .secondaryLabel
            label.numberOfLines = 1
            return label
        }()

        private lazy var valueLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
            label.textColor = .label
            return label
        }()

        private lazy var unitLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 9, weight: .medium)
            label.textColor = .secondaryLabel
            return label
        }()
    }
}
