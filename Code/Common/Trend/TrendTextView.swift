//
//  TrendTextView.swift
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

    @objc(DOTrendTextView)
    final class TrendTextView: UIView {

        private enum Metrics {
            static let horizontalPadding: CGFloat = 10
            static let verticalPadding: CGFloat = 6
        }

        private static let separator = "  ·  "

        private var reservedWidth: CGFloat = 0

        private let label: UILabel = {
            let label = UILabel()
            label.numberOfLines = 1
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            addSubview(label)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            label.frame = bounds.insetBy(dx: Metrics.horizontalPadding, dy: Metrics.verticalPadding)
        }

        func render(_ charts: [DO.TrendChart], now: TimeInterval) {
            label.attributedText = text(for: charts, now: now, placeholder: false)
            reservedWidth = text(for: charts, now: now, placeholder: true).size().width
            setNeedsLayout()
        }

        override var intrinsicContentSize: CGSize { sizeThatFits(.zero) }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let content = max(label.intrinsicContentSize.width, reservedWidth)
            return CGSize(
                width: content + Metrics.horizontalPadding * 2,
                height: label.intrinsicContentSize.height + Metrics.verticalPadding * 2
            )
        }

        private func text(for charts: [DO.TrendChart], now: TimeInterval, placeholder: Bool) -> NSAttributedString {
            let result = NSMutableAttributedString()

            let name: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.62),
            ]
            let number: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.95),
            ]

            for (index, chart) in charts.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(string: Self.separator, attributes: name))
                }
                result.append(NSAttributedString(string: chart.title + " ", attributes: name))

                let value = placeholder ? "888" : chart.valueText(at: now)
                result.append(NSAttributedString(string: value, attributes: number))

                if !chart.unit.isEmpty {
                    result.append(NSAttributedString(string: " " + chart.unit, attributes: name))
                }
            }
            return result
        }
    }
}
