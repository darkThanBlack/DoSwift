//
//  PerfTimelineCell.swift
//  DoSwift
//

import UIKit

/// 详情页顶部的时间线：**三条 lane 共用一个横轴**，整段会话压在一屏里。
///
/// 它只负责定位和选择——点一下把「范围」挪到那里。不滑动、不缩放：
/// 一旦允许滑动或缩放，就会出现「看到的范围」和「统计的范围」两个数。
///
/// 每条 lane 自带纵轴标注（量程上限与峰值）、阈值虚线。横轴在底部给三个时刻。
final class PerfTimelineCell: UITableViewCell {

    static let cellHeight: CGFloat = 152

    /// 点了一下，回调点中的时刻
    var onSelect: ((TimeInterval) -> Void)?

    private var charts: [TrendChart] = []
    private var start: TimeInterval = 0
    private var end: TimeInterval = 1
    private var scope: ClosedRange<TimeInterval>?

    private enum Metrics {
        static let inset: CGFloat = 14
        static let top: CGFloat = 6
        static let laneHeight: CGFloat = 32
        static let laneGap: CGFloat = 14
        static let axisHeight: CGFloat = 18
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - Configure

    func configure(charts: [TrendChart], start: TimeInterval, end: TimeInterval, scope: ClosedRange<TimeInterval>?) {
        self.charts = charts
        self.start = start
        self.end = max(end, start + 0.001)
        self.scope = scope
        setNeedsDisplay()
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        isOpaque = false

        contentView.heightAnchor.constraint(equalToConstant: Self.cellHeight).isActive = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Tap

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let x = gesture.location(in: self).x - Metrics.inset
        let width = bounds.width - Metrics.inset * 2
        guard width > 0 else { return }

        let ratio = min(max(x / width, 0), 1)
        onSelect?(start + TimeInterval(ratio) * (end - start))
    }

    // MARK: - Draw

    private var labelAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel,
        ]
    }

    private var valueAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel,
        ]
    }

    override func draw(_ rect: CGRect) {
        guard !charts.isEmpty else { return }

        let left = Metrics.inset
        let width = bounds.width - Metrics.inset * 2
        let span = end - start
        guard width > 0, span > 0 else { return }

        // 选中范围先铺一层底，压在曲线下面
        if let scope = scope {
            let x0 = left + CGFloat((scope.lowerBound - start) / span) * width
            let x1 = left + CGFloat((scope.upperBound - start) / span) * width
            UIColor.label.withAlphaComponent(0.08).setFill()
            UIBezierPath(
                roundedRect: CGRect(x: x0, y: 2, width: max(x1 - x0, 3), height: bounds.height - 22),
                cornerRadius: 4
            ).fill()
        }

        for (index, chart) in charts.prefix(3).enumerated() {
            let top = Metrics.top + CGFloat(index) * (Metrics.laneHeight + Metrics.laneGap)
            let lane = CGRect(x: left, y: top, width: width, height: Metrics.laneHeight)

            let lower = chart.range.lowerBound
            let rangeSpan = max(chart.range.upperBound - lower, .ulpOfOne)
            func y(_ value: Double) -> CGFloat {
                let ratio = min(max((value - lower) / rangeSpan, 0), 1)
                return lane.maxY - CGFloat(ratio) * lane.height
            }

            // 纵轴：量程上限放在 lane 右上，它就是这条线的天花板
            let ceiling = "\(Int(chart.range.upperBound.rounded())) \(chart.unit)"
            let ceilingSize = (ceiling as NSString).size(withAttributes: valueAttributes)
            (ceiling as NSString).draw(
                at: CGPoint(x: lane.maxX - ceilingSize.width, y: lane.minY - 1),
                withAttributes: valueAttributes
            )

            // lane 名
            (chart.title as NSString).draw(
                at: CGPoint(x: lane.minX, y: lane.minY - 1),
                withAttributes: labelAttributes
            )

            // 阈值虚线
            if let threshold = chart.threshold, chart.range.contains(threshold.value) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: lane.minX, y: y(threshold.value)))
                path.addLine(to: CGPoint(x: lane.maxX, y: y(threshold.value)))
                path.setLineDash([3, 3], count: 2, phase: 0)
                UIColor.tertiaryLabel.setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            // 基线
            let base = UIBezierPath()
            base.move(to: CGPoint(x: lane.minX, y: lane.maxY))
            base.addLine(to: CGPoint(x: lane.maxX, y: lane.maxY))
            UIColor.separator.setStroke()
            base.lineWidth = 0.5
            base.stroke()

            guard chart.points.count > 1 else { continue }

            // 一屏几千个点时按步长抽稀：每像素最多两点
            let step = max(1, chart.points.count / max(Int(width * 2), 1))
            // 抽稀之后相邻两个绘制点本来就在时间上隔了 step 个采样，
            // 断档阈值必须跟着放大，否则每一段都会被当成断档而不连
            let gapLimit = chart.interval * Double(step) * 2
            let color: UIColor = index == 0 ? .systemBlue : (index == 1 ? .systemOrange : .systemGreen)

            let line = UIBezierPath()
            var started = false
            var previous: TimeInterval = 0
            var cursor = 0
            while cursor < chart.points.count {
                let point = chart.points[cursor]
                cursor += step

                guard point.t >= start, point.t <= end else { continue }
                if started, point.t - previous > gapLimit { started = false }

                let x = left + CGFloat((point.t - start) / span) * width
                let cg = CGPoint(x: x, y: y(point.v))
                if started { line.addLine(to: cg) } else { line.move(to: cg); started = true }
                previous = point.t
            }

            color.setStroke()
            line.lineWidth = 1.2
            line.lineJoinStyle = .round
            line.stroke()

        }

        // 横轴：三个时刻
        let axisY = Metrics.top + 3 * (Metrics.laneHeight + Metrics.laneGap) - Metrics.laneGap + 2
        let positions: [(CGFloat, TimeInterval)] = [
            (left, start),
            (left + width / 2, start + span / 2),
            (left + width, end),
        ]
        let now = CACurrentMediaTime()
        for (x, time) in positions {
            let text = Self.timeFormatter.string(from: Date(timeIntervalSinceNow: time - now))
            let size = (text as NSString).size(withAttributes: valueAttributes)
            let originX = x == left ? x : (x == left + width ? x - size.width : x - size.width / 2)
            (text as NSString).draw(at: CGPoint(x: originX, y: axisY), withAttributes: valueAttributes)
        }
    }
}
