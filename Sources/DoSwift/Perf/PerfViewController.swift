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
            title = "性能"
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
                        title: "检测",
                        detail: Self.detail(for: chart),
                        isOn: DO.PerfTrendPlugin.shared.isEnabled(index)
                    )
                }
            ]

            if index == 2 {
                rows.append(Row(cellClass: DO.SelectorCell.self, onTrigger: { [weak self] _ in
                    self?.chooseMemoryMetric()
                }) { cell in
                    cell.update(title: "测量方式", detail: DO.PerfTrendPlugin.shared.memoryMetric.title)
                })
            }

            let footer = (index == 2) ? "两种口径量的不是一回事：进程占用是系统杀进程看的量，堆分配只覆盖 malloc。换口径会清空已采数据。" : nil
            return Section(title: chart.title, footer: footer, rows: rows)
        }

        private func chooseMemoryMetric() {
            let metrics = DO.PerfMemoryMetric.allCases
            let current = DO.PerfTrendPlugin.shared.memoryMetric

            let alert = UIAlertController(
                title: "内存测量方式",
                message: "当前：\(current.title)",
                preferredStyle: .alert
            )
            for metric in metrics {
                alert.addAction(UIAlertAction(title: metric.title, style: .default) { [weak self] _ in
                    DO.PerfTrendPlugin.shared.setMemoryMetric(metric)
                    self?.reload()
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        }

        private func styleSection() -> Section {
            let plugin = DO.PerfTrendPlugin.shared
            return Section(
                title: "显示",
                footer: "两种样式读的是同一批数据，换样式不会清空任何历史。",
                rows: [
                    Row(cellClass: DO.SelectorCell.self, onTrigger: { [weak self] _ in
                        self?.chooseStyle()
                    }) { cell in
                        cell.update(title: "浮窗样式", detail: plugin.displayStyle.title)
                    }
                ]
            )
        }

        private func closeSection() -> Section {
            return Section(rows: [
                Row(cellClass: DO.ActionCell.self, onTrigger: { _ in
                    DO.PerfTrendPlugin.shared.hide()
                }) { cell in
                    cell.update(title: "关闭浮窗", isDestructive: true)
                }
            ])
        }

        private func presentCannotDisableLast() {
            let alert = UIAlertController(
                title: nil,
                message: "至少要保留一个指标。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
        }

        private func chooseStyle() {
            let styles = DO.TrendDisplayStyle.allCases
            let current = DO.PerfTrendPlugin.shared.displayStyle

            let alert = UIAlertController(
                title: "浮窗样式",
                message: "当前：\(current.title)",
                preferredStyle: .alert
            )
            for style in styles {
                alert.addAction(UIAlertAction(title: style.title, style: .default) { [weak self] _ in
                    DO.PerfTrendPlugin.shared.setDisplayStyle(style)
                    self?.reload()
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        }

        private static func detail(for chart: DO.TrendChart) -> String {
            let lower = Int(chart.range.lowerBound.rounded())
            let upper = Int(chart.range.upperBound.rounded())
            let range = "\(lower)–\(upper) \(chart.unit)"

            switch chart.threshold {
            case .above(let value): return "\(range) · 高于 \(Int(value)) 标红"
            case .below(let value): return "\(range) · 低于 \(Int(value)) 标红"
            case .none:             return range
            }
        }
    }
}
