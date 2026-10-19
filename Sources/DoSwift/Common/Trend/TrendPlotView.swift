//
//  TrendPlotView.swift
//  DoSwift
//

import UIKit

/// 曲线区：**只画自己的 bounds**，不知道卡片多大、边距多少。
///
/// 它属于 UI 层里「取数 + 绘制」的那一半：给一个时间区间，从序列里取出点列
/// （数据层负责切段），然后决定怎么画——线宽、填充、阈值线、告警配色都在这里。
final class TrendPlotView: UIView {

    /// 展示窗口的长度，单位秒。**UI 层的旋钮**：决定「一秒走多少像素」，
    /// 和源的采样率无关（横轴按时间戳定位，点稀只是线显得折得硬）。
    var span: TimeInterval = 30

    private var chart: TrendChart?
    private var now: TimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Render

    /// 画这一帧。由持有者按自己的节奏调——可以比采样密，重画永远不写数据。
    func render(_ chart: TrendChart?, now: TimeInterval) {
        self.chart = chart
        self.now = now
        setNeedsDisplay()
    }

    // MARK: - Draw

    /// 直接 `draw(_:)` 而不是维护几层 `CAShapeLayer`：一秒才重画几次，
    /// 那点开销不值得换一套图层增删的复杂度。
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let chart = chart else { return }

        let plot = bounds
        let lower = chart.range.lowerBound
        let range = max(chart.range.upperBound - lower, .ulpOfOne)

        func plotY(_ value: Double) -> CGFloat {
            let ratio = min(max((value - lower) / range, 0), 1)
            return plot.maxY - CGFloat(ratio) * plot.height
        }

        let trace = chart.isAlarming(at: now) ? UIColor.systemRed : UIColor.label

        // 阈值线：给告警一个参照物——「离那条线还差多少」是能直接看出来的距离
        if let threshold = chart.threshold {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: plot.minX, y: plotY(threshold.value)))
            path.addLine(to: CGPoint(x: plot.maxX, y: plotY(threshold.value)))
            path.setLineDash([2, 2], count: 2, phase: 0)
            path.lineWidth = 1
            (chart.isAlarming(at: now) ? UIColor.systemRed.withAlphaComponent(0.6) : UIColor.tertiaryLabel)
                .setStroke()
            path.stroke()
        }

        let from = now - span
        // 数据层给的是**分段后的点列**：段与段之间就是断档。
        // 这里只管把每段连起来，「为什么断」不归它管
        let segments = chart.points.segments(from: from, to: now, gap: chart.interval * 1.5)
        guard let lastSegment = segments.last, let lastPoint = lastSegment.last else { return }

        func plotX(_ time: TimeInterval) -> CGFloat {
            plot.minX + CGFloat((time - from) / span) * plot.width
        }

        for segment in segments {
            let points = segment.map { CGPoint(x: plotX($0.t), y: plotY($0.v)) }
            guard !points.isEmpty else { continue }

            // 填充：让「多少」有体量感，不只是一根线
            if points.count > 1 {
                let area = UIBezierPath()
                area.move(to: CGPoint(x: points[0].x, y: plot.maxY))
                points.forEach { area.addLine(to: $0) }
                area.addLine(to: CGPoint(x: points[points.count - 1].x, y: plot.maxY))
                area.close()
                trace.withAlphaComponent(0.13).setFill()
                area.fill()
            }

            let line = UIBezierPath()
            line.move(to: points[0])
            points.dropFirst().forEach { line.addLine(to: $0) }
            line.lineWidth = 1.5
            line.lineJoinStyle = .round
            line.lineCapStyle = .round
            trace.withAlphaComponent(0.85).setStroke()
            line.stroke()
        }

        // 末点：一个实心小圆，指出「现在到这儿」
        let end = CGPoint(x: plotX(lastPoint.t), y: plotY(lastPoint.v))
        context.setFillColor(trace.cgColor)
        context.fillEllipse(in: CGRect(x: end.x - 1.5, y: end.y - 1.5, width: 3, height: 3))
    }
}
