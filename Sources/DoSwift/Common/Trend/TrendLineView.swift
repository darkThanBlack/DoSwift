//
//  TrendLineView.swift
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

    final class TrendLineView: UIView {

        private enum Metrics {
            static let size = CGSize(width: 112, height: 66)
            static let horizontalPadding: CGFloat = 12
            static let verticalPadding: CGFloat = 10
            static let headerHeight: CGFloat = 20
            static let spacing: CGFloat = 6
            static let plotHeight: CGFloat = 20
        }

        var span: TimeInterval = 30

        private let header = DO.TrendHeaderView()
        private let plot = DO.TrendPlotView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isOpaque = false
            loadViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize { Metrics.size }
        override func sizeThatFits(_ size: CGSize) -> CGSize { Metrics.size }

        func render(_ chart: DO.TrendChart?, now: TimeInterval) {
            header.render(chart, now: now)

            guard let chart = chart else {
                plot.render(nil)
                return
            }
            plot.render(chart.plotContent(
                for: CGSize(
                    width: Metrics.size.width - Metrics.horizontalPadding * 2,
                    height: Metrics.plotHeight
                ),
                window: (now - span)...now,
                tint: chart.isAlarming(at: now) ? .systemRed : .label
            ))
        }

        private func loadViews() {
            header.translatesAutoresizingMaskIntoConstraints = false
            plot.translatesAutoresizingMaskIntoConstraints = false
            addSubview(header)
            addSubview(plot)

            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.verticalPadding),
                header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
                header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
                header.heightAnchor.constraint(equalToConstant: Metrics.headerHeight),

                plot.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Metrics.spacing),
                plot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
                plot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
                plot.heightAnchor.constraint(equalToConstant: Metrics.plotHeight),
            ])
        }
    }
}
