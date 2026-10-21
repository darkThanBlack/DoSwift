//
//  PerfViewController.swift
//  DoSwift
//

import UIKit

/// 「性能」工具页。
///
/// 每个指标一段，段里第一项是它自己的**检测开关**；末尾是公共的样式选择与
/// 「关闭浮窗」。**不允许把三个都关掉**——浮窗没有可显示的指标就没有意义了。
///
/// 这一页不持有任何状态，开关、当前指标、样式全在 `PerfTrendPlugin`，
/// 每次出现时回填。
final class PerfViewController: SectionTableViewController {

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "性能"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 浮窗可能在别处被单击换过指标，每次出现都从真相回填
        reload()
    }

    /// 关闭**只关这一页**：浮窗留着，用户可以退回业务 App 继续看。
    /// 收浮窗走页底那颗按钮，整页连浮窗一起收起是两步。
    override func close() {
        dismiss(animated: true) {
            PerfTrendPlugin.shared.settingsDidDismiss()
        }
    }

    // MARK: - Content

    private func reload() {
        var result: [Section] = []
        for index in 0..<PerfTrendPlugin.metricCount {
            if let section = metricSection(at: index) {
                result.append(section)
            }
        }
        result.append(styleSection())
        result.append(closeSection())
        sections = result
    }

    /// 一个指标一段：段标题是指标名，段里第一行是「检测」开关。
    /// 后面还会往这一段里加这个指标自己的选项（采样间隔、阈值之类）。
    private func metricSection(at index: Int) -> Section? {
        guard let chart = PerfTrendPlugin.shared.chart(at: index) else { return nil }

        var rows: [Row] = [
            Row(cellClass: ToggleCell.self, onTrigger: { [weak self] cell in
                guard let self = self else { return }
                if !PerfTrendPlugin.shared.setEnabled(cell.isOn, for: index) {
                    self.presentCannotDisableLast()
                }
                self.reload()
            }) { cell in
                cell.update(
                    title: "检测",
                    detail: Self.detail(for: chart),
                    isOn: PerfTrendPlugin.shared.isEnabled(index)
                )
            }
        ]

        // 内存有两种口径：进程占用（jetsam 口径）和 malloc 堆。换口径会清空已采的数据。
        if index == 2 {
            rows.append(Row(cellClass: SelectorCell.self, onTrigger: { [weak self] _ in
                self?.chooseMemoryMetric()
            }) { cell in
                cell.update(title: "测量方式", detail: PerfTrendPlugin.shared.memoryMetric.title)
            })
        }

        // 内存这一段多一句：换口径会把已经采到的历史清掉
        let footer = (index == 2) ? "两种口径量的不是一回事：进程占用是系统杀进程看的量，堆分配只覆盖 malloc。换口径会清空已采数据。" : nil
        return Section(title: chart.title, footer: footer, rows: rows)
    }

    /// 用 **`.alert`** 而不是 `.actionSheet`：后者在 iPad / Mac 上会变成锚在
    /// 控件旁边的小气泡，而这个选择器没有「锚点」的语义。`.alert` 在哪儿都是居中的。
    private func chooseMemoryMetric() {
        let metrics = PerfMemoryMetric.allCases
        let current = PerfTrendPlugin.shared.memoryMetric

        let alert = UIAlertController(
            title: "内存测量方式",
            message: "当前：\(current.title)",
            preferredStyle: .alert
        )
        for metric in metrics {
            alert.addAction(UIAlertAction(title: metric.title, style: .default) { [weak self] _ in
                PerfTrendPlugin.shared.setMemoryMetric(metric)
                self?.reload()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func styleSection() -> Section {
        let plugin = PerfTrendPlugin.shared
        return Section(
            title: "显示",
            footer: "两种样式读的是同一批数据，换样式不会清空任何历史。",
            rows: [
                Row(cellClass: SelectorCell.self, onTrigger: { [weak self] _ in
                    self?.chooseStyle()
                }) { cell in
                    cell.update(title: "浮窗样式", detail: plugin.displayStyle.title)
                }
            ]
        )
    }

    private func closeSection() -> Section {
        return Section(rows: [
            Row(cellClass: ActionCell.self, onTrigger: { _ in
                PerfTrendPlugin.shared.setVisible(false)
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
        let styles = TrendDisplayStyle.allCases
        let current = PerfTrendPlugin.shared.displayStyle

        let alert = UIAlertController(
            title: "浮窗样式",
            message: "当前：\(current.title)",
            preferredStyle: .alert
        )
        for style in styles {
            alert.addAction(UIAlertAction(title: style.title, style: .default) { [weak self] _ in
                PerfTrendPlugin.shared.setDisplayStyle(style)
                self?.reload()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    /// 副标题把这条源的两个关键参数写出来：量程和阈值。
    /// 阈值的方向写进文案里，免得看到「50」不知道是高了坏还是低了坏。
    private static func detail(for chart: TrendChart) -> String {
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
