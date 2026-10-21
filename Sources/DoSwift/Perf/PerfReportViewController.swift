//
//  PerfReportViewController.swift
//  DoSwift
//

import UIKit

/// 性能详情：从启动到现在的整份会话记录。
///
/// 结构只有三层：**时间线**（定位和选范围）、**范围条**（说清在看哪一段）、
/// **三张文字卡**（那一段的账）。没有图表编码与文字并存——除了顶部那条时间线，
/// 它的职责只是"点哪儿看哪儿"。
///
/// 所有数字都随范围变：换一段，四张卡的数就换成那一段的。整段只是默认范围。
final class PerfReportViewController: SectionTableViewController {

    /// nil = 整段会话
    private var scope: ClosedRange<TimeInterval>?

    /// 点选的窗口宽度。三张卡共用一个范围，所以只能有一个宽度——
    /// 内存想要 5 分钟、帧率想要 30 秒，1 分钟是两者的折中。
    private let pickWindow: TimeInterval = 60

    /// 会话是活的，数字要跟着长。2 秒重算一次：够快，又不会让读数一直跳。
    private var refreshTimer: Timer?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "性能"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// 关闭详情页 = 收起整个工具
    override func close() {
        dismiss(animated: true) {
            PerfTrendPlugin.shared.settingsDidDismiss()
        }
    }

    @objc private func showSettings() {
        let navigator = UINavigationController(rootViewController: PerfViewController())
        navigator.isModalInPresentation = true
        present(navigator, animated: true)
    }

    // MARK: - Content

    private var now: TimeInterval { CACurrentMediaTime() }

    /// 0 = 帧率，1 = CPU，2 = 内存（与 `PerfTrendPlugin.allCharts` 同序）
    private func chart(at index: Int) -> TrendChart? {
        return PerfTrendPlugin.shared.chart(at: index)
    }

    private var sessionRange: ClosedRange<TimeInterval> {
        let starts = (0..<PerfTrendPlugin.metricCount).compactMap { chart(at: $0)?.points.first?.t }
        let start = starts.min() ?? now
        return start...max(now, start + 0.001)
    }

    private var activeRange: ClosedRange<TimeInterval> { scope ?? sessionRange }

    private func reload() {
        let session = sessionRange
        let range = activeRange

        sections = [
            Section(title: "总览", rows: [timelineRow(session: session, range: range)]),
            Section(rows: [scopeRow(range: range)]),
            card(title: "内存", rows: memoryRows(in: range)),
            card(title: "CPU", rows: cpuRows(in: range)),
            card(title: "帧率", rows: fpsRows(in: range)),
        ]
    }

    private func timelineRow(session: ClosedRange<TimeInterval>,
                             range: ClosedRange<TimeInterval>) -> Row {
        let charts = (0..<PerfTrendPlugin.metricCount).compactMap { chart(at: $0) }
        return Row(cellClass: PerfTimelineCell.self) { cell in
            cell.configure(
                charts: charts,
                start: session.lowerBound,
                end: session.upperBound,
                scope: range
            )
            cell.onSelect = { [weak self] time in
                self?.select(around: time)
            }
        }
    }

    private func scopeRow(range: ClosedRange<TimeInterval>) -> Row {
        let isFull = (scope == nil)
        let now = self.now
        return Row(cellClass: PerfScopeCell.self) { cell in
            cell.configure(range: range, isFull: isFull, now: now)
            cell.onSelectAll = { [weak self] in
                self?.scope = nil
                self?.reload()
            }
        }
    }

    private func card(title: String, rows: [(String, String)]) -> Section {
        return Section(title: title, rows: rows.map { pair in
            Row(cellClass: KeyValueCell.self) { cell in
                cell.update(title: pair.0, detail: pair.1)
            }
        })
    }

    /// 以点中的时刻为中心取一段，夹在会话范围内
    private func select(around time: TimeInterval) {
        let session = sessionRange
        let half = pickWindow / 2
        var lower = time - half
        var upper = time + half
        if lower < session.lowerBound {
            upper += session.lowerBound - lower
            lower = session.lowerBound
        }
        if upper > session.upperBound {
            lower -= upper - session.upperBound
            upper = session.upperBound
        }
        scope = max(lower, session.lowerBound)...min(upper, session.upperBound)
        reload()
    }

    // MARK: - 各卡片

    private func memoryRows(in range: ClosedRange<TimeInterval>) -> [(String, String)] {
        let points = chart(at: 2)?.points.filter { range.contains($0.t) } ?? []
        let samples = PerfTrendPlugin.shared.memorySamples.filter { range.contains($0.t) }

        let budget = PerfTrendPlugin.shared.memoryTotalMB
        let average = mean(points.map(\.v))
        let peak = points.map(\.v).max()

        // 堆口径拿不到分项，这三项和「其余」会退化成 —
        let graphics = mean(samples.compactMap(\.graphics))
        let media = mean(samples.compactMap(\.media))
        let network = mean(samples.compactMap(\.network))
        let rest: Double? = (graphics == nil && media == nil && network == nil)
            ? nil
            : average.map { max($0 - (graphics ?? 0) - (media ?? 0) - (network ?? 0), 0) }

        func row(_ title: String, _ value: Double?) -> (String, String) {
            guard let value = value else { return (title, "—") }
            var text = "\(Int(value.rounded())) MB"
            if let budget = budget, budget > 0 {
                text += " · \(Int((value / budget * 100).rounded()))%"
            }
            return (title, text)
        }

        return [
            ("总额", budget.map { "\(Int($0.rounded())) MB" } ?? "—"),
            row("平均", average),
            row("峰值", peak),
            row("图形", graphics),
            row("媒体", media),
            row("网络", network),
            row("其余", rest),
        ]
    }

    private func cpuRows(in range: ClosedRange<TimeInterval>) -> [(String, String)] {
        guard let chart = chart(at: 1) else { return [("平均占用", "—")] }
        let points = chart.points.filter { range.contains($0.t) }
        let samples = PerfTrendPlugin.shared.cpuSamples.filter { range.contains($0.t) }

        // 累计时间 = 首尾两个累计值的差。**不做积分**——积分对采样密度、定时器抖动、
        // 断档都敏感，而累计值由内核维护，差分是精确的。
        var seconds: TimeInterval?
        if samples.count > 1, let first = samples.first, let last = samples.last {
            // 逐线程累计，线程退出会让总和变小——负值时按 0 处理
            let delta = last.totalUsec >= first.totalUsec ? last.totalUsec - first.totalUsec : 0
            seconds = Double(delta) / 1_000_000
        }

        return [
            ("平均占用", percent(mean(points.map(\.v)))),
            ("峰值", percent(points.map(\.v).max())),
            ("累计 CPU 时间", seconds.map(duration) ?? "—"),
        ]
    }

    private func fpsRows(in range: ClosedRange<TimeInterval>) -> [(String, String)] {
        guard let chart = chart(at: 0) else { return [("平均帧率", "—")] }
        let points = chart.points.filter { range.contains($0.t) }
        let samples = PerfTrendPlugin.shared.frameSamples.filter { range.contains($0.t) }

        return [
            ("平均帧率", mean(points.map(\.v)).map { "\(Int($0.rounded())) fps" } ?? "—"),
            ("慢帧", "\(samples.reduce(0) { $0 + $1.slow })"),
            ("冻结帧", "\(samples.reduce(0) { $0 + $1.frozen })"),
            ("总帧数", "\(samples.reduce(0) { $0 + $1.frames })"),
        ]
    }

    // MARK: - 格式

    private func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func percent(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        return "\(Int(value.rounded()))%"
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        guard total >= 60 else { return "\(total) 秒" }
        return String(format: "%d 分 %02d 秒", total / 60, total % 60)
    }
}
