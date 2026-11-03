//
//  PerfViewController.swift
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

    @objc(DOPerfViewController)
    final class PerfViewController: DO.SectionTableViewController {

        override func viewDidLoad() {
            super.viewDidLoad()
            title = DO.Text.Perf.title
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reload()
        }

        override func close() {
            dismiss(animated: true) {
                DO.PerfTrendPlugin.shared.settingsDidDismiss()
            }
        }

        private func reload() {
            var result: [Section] = []
            for index in 0..<DO.PerfTrendPlugin.metricCount {
                if let section = metricSection(at: index) {
                    result.append(section)
                }
            }
            result.append(styleSection())
            result.append(closeSection())
            sections = result
        }

        private func metricSection(at index: Int) -> Section? {
            guard let chart = DO.PerfTrendPlugin.shared.chart(at: index) else { return nil }

            var rows: [Row] = [
                Row(cellClass: DO.ToggleCell.self, onTrigger: { [weak self] cell in
                    guard let self = self else { return }
                    if !DO.PerfTrendPlugin.shared.setEnabled(cell.isOn, for: index) {
                        self.presentCannotDisableLast()
                    }
                    self.reload()
                }) { cell in
                    cell.update(
                        title: DO.Text.Perf.toggleDetect,
                        detail: Self.detail(for: chart),
                        isOn: DO.PerfTrendPlugin.shared.isEnabled(index)
                    )
                }
            ]

            if index == 2 {
                rows.append(Row(cellClass: DO.SelectorCell.self, onTrigger: { [weak self] _ in
                    self?.chooseMemoryMetric()
                }) { cell in
                    cell.update(title: DO.Text.Perf.memoryMetric, value: DO.PerfTrendPlugin.shared.memoryMetric.title)
                })
            }

            let footer = (index == 2) ? DO.Text.Perf.memoryMetricFooter : nil
            return Section(title: chart.title, footer: footer, rows: rows)
        }

        private func chooseMemoryMetric() {
            let metrics = DO.PerfMemoryMetric.allCases
            let current = DO.PerfTrendPlugin.shared.memoryMetric

            let alert = UIAlertController(
                title: DO.Text.Perf.memoryMetricAlert,
                message: DO.Text.Perf.current(current.title),
                preferredStyle: .alert
            )
            for metric in metrics {
                alert.addAction(UIAlertAction(title: metric.title, style: .default) { [weak self] _ in
                    DO.PerfTrendPlugin.shared.setMemoryMetric(metric)
                    self?.reload()
                })
            }
            alert.addAction(UIAlertAction(title: DO.Text.Common.cancel, style: .cancel))
            present(alert, animated: true)
        }

        private func styleSection() -> Section {
            let plugin = DO.PerfTrendPlugin.shared
            return Section(
                title: DO.Text.Perf.displaySection,
                footer: DO.Text.Perf.displayFooter,
                rows: [
                    Row(cellClass: DO.SelectorCell.self, onTrigger: { [weak self] _ in
                        self?.chooseStyle()
                    }) { cell in
                        cell.update(title: DO.Text.Perf.floatingStyle, value: plugin.displayStyle.title)
                    }
                ]
            )
        }

        private func closeSection() -> Section {
            return Section(footer: DO.Text.Perf.longPressTip, rows: [
                Row(cellClass: DO.ActionCell.self, onTrigger: { _ in
                    DO.PerfTrendPlugin.shared.dismissAll()
                }) { cell in
                    cell.update(title: DO.Text.Perf.closeFloating, isDestructive: true)
                }
            ])
        }

        private func presentCannotDisableLast() {
            let alert = UIAlertController(
                title: nil,
                message: DO.Text.Perf.cannotDisableLast,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: DO.Text.Common.ok, style: .default))
            present(alert, animated: true)
        }

        private func chooseStyle() {
            let styles = DO.TrendDisplayStyle.allCases
            let current = DO.PerfTrendPlugin.shared.displayStyle

            let alert = UIAlertController(
                title: DO.Text.Perf.floatingStyle,
                message: DO.Text.Perf.current(current.title),
                preferredStyle: .alert
            )
            for style in styles {
                alert.addAction(UIAlertAction(title: style.title, style: .default) { [weak self] _ in
                    DO.PerfTrendPlugin.shared.setDisplayStyle(style)
                    self?.reload()
                })
            }
            alert.addAction(UIAlertAction(title: DO.Text.Common.cancel, style: .cancel))
            present(alert, animated: true)
        }

        private static func detail(for chart: DO.TrendChart) -> String {
            let lower = Int(chart.range.lowerBound.rounded())
            let upper = Int(chart.range.upperBound.rounded())
            let range = "\(lower)–\(upper) \(chart.unit)"

            switch chart.threshold {
            case .above(let value): return DO.Text.Perf.thresholdAbove(range: range, value: Int(value))
            case .below(let value): return DO.Text.Perf.thresholdBelow(range: range, value: Int(value))
            case .none:             return range
            }
        }
    }
}
