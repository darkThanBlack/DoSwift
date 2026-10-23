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
/// 每条 lane 自带量程上限与阈值虚线，横轴在底部给三个时刻。
/// 曲线本身交给 `TrendPlotView`——和浮窗共用同一个绘制实现。
final class PerfTimelineCell: UITableViewCell {

    static let cellHeight: CGFloat = 152

    /// 点了一下，回调点中的时刻
    var onSelect: ((TimeInterval) -> Void)?

    private var charts: [TrendChart] = []
    private var start: TimeInterval = 0
    private var end: TimeInterval = 1
    private var scope: ClosedRange<TimeInterval>?

    /// 一条 lane 一个绘制视图。曲线本身不在这里画——这里只画「框」：
    /// 选中带、lane 名、量程上限、基线、底部时刻。
    private var plots: [TrendPlotView] = []

    private enum Metrics {
        static let inset: CGFloat = 14
        static let top: CGFloat = 6
        static let laneHeight: CGFloat = 32
        static let laneGap: CGFloat = 14
        static let laneCount = 3
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
        setNeedsLayout()
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

        plots = (0..<Metrics.laneCount).map { _ in
            let plot = TrendPlotView()
            contentView.addSubview(plot)
            return plot
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func laneFrame(_ index: Int) -> CGRect {
        CGRect(
            x: Metrics.inset,
            y: Metrics.top + CGFloat(index) * (Metrics.laneHeight + Metrics.laneGap),
            width: max(bounds.width - Metrics.inset * 2, 0),
            height: Metrics.laneHeight
        )
    }

    /// 曲线的像素换算依赖 plot 的真实宽度（抽稀步长由它定），所以渲染放在布局里：
    /// 宽度一变，步长就要重算。
    override func layoutSubviews() {
        super.layoutSubviews()

        let window = start...end
        for (index, plot) in plots.enumerated() {
            plot.frame = laneFrame(index)

            guard index < charts.count else {
                plot.isHidden = true
                plot.render(nil)
                continue
            }
            plot.isHidden = false
            plot.render(charts[index].plotContent(for: plot.bounds.size, window: window))
        }
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

    /// 只画框和字。曲线由 `plots` 各自绘制，见 `layoutSubviews`。
    override func draw(_ rect: CGRect) {
        guard !charts.isEmpty else { return }

        let left = Metrics.inset
        let width = bounds.width - Metrics.inset * 2
        let span = end - start
        guard width > 0, span > 0 else { return }

        // 选中范围先铺一层底，压在曲线下面（contentView 是子层，画在这之后）
        if let scope = scope {
            let x0 = left + CGFloat((scope.lowerBound - start) / span) * width
            let x1 = left + CGFloat((scope.upperBound - start) / span) * width
            UIColor.label.withAlphaComponent(0.08).setFill()
            UIBezierPath(
                roundedRect: CGRect(x: x0, y: 2, width: max(x1 - x0, 3), height: bounds.height - 22),
                cornerRadius: 4
            ).fill()
        }

        for (index, chart) in charts.prefix(Metrics.laneCount).enumerated() {
            let lane = laneFrame(index)

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

            // 基线
            let base = UIBezierPath()
            base.move(to: CGPoint(x: lane.minX, y: lane.maxY))
            base.addLine(to: CGPoint(x: lane.maxX, y: lane.maxY))
            UIColor.separator.setStroke()
            base.lineWidth = 0.5
            base.stroke()
        }

        // 横轴：三个时刻
        let axisY = laneFrame(Metrics.laneCount - 1).maxY + 2
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
