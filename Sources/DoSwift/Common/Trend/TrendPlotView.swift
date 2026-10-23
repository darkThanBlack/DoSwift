//
//  TrendPlotView.swift
//  DoSwift
//

import UIKit

/// 一次绘制需要的全部东西，**不含任何业务语义**：没有时间、量程、单位、告警。
///
/// 这些都是「归一化之后的位置」——怎么算出来的不归绘制层管。
struct TrendPlotContent {

    /// 归一化坐标，**原点在左下**：x 0…1 从左到右，y 0…1 从下到上。
    ///
    /// 每个子数组是一条**连续**折线，子数组之间就是断档。为什么不给一维数组：
    /// 一维表达不了「这两点之间不该连」，view 要么画出一条横跨断档的长斜线，
    /// 要么自己猜一个断档规则——而它手里没有采样间隔，没这个资格。
    let segments: [[CGPoint]]

    /// 阈值线的归一化纵坐标，nil 表示不画
    let threshold: Double?

    /// 曲线颜色。告警变红也走这里，view 自己不判告警。
    let tint: UIColor
}

/// 曲线区：**只画自己的 bounds**，不知道卡片多大、边距多少。
///
/// 它只做两件事：把归一化坐标换算成像素，然后把折线画出来。
/// 取点、抽稀、切段、归一化都在 `TrendChart.plotContent(for:window:tint:)` 里。
final class TrendPlotView: UIView {

    private var content: TrendPlotContent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        // 触摸留给外面（浮窗要拖动、时间线要点选），曲线本身不接事件
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Render

    /// 画这一帧。由持有者按自己的节奏调——可以比采样密，重画永远不写数据。
    func render(_ content: TrendPlotContent?) {
        self.content = content
        setNeedsDisplay()
    }

    // MARK: - Draw

    /// 直接 `draw(_:)` 而不是维护几层 `CAShapeLayer`：一秒才重画几次，
    /// 那点开销不值得换一套图层增删的复杂度。
    override func draw(_ rect: CGRect) {
        guard let content = content, bounds.width > 0, bounds.height > 0 else { return }

        let plot = bounds

        // 唯一的换算：归一化 → 像素
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: plot.minX + point.x * plot.width,
                y: plot.maxY - point.y * plot.height
            )
        }

        // 阈值线：给告警一个参照物——「离那条线还差多少」是能直接看出来的距离
        if let threshold = content.threshold {
            let y = plot.maxY - CGFloat(threshold) * plot.height
            let path = UIBezierPath()
            path.move(to: CGPoint(x: plot.minX, y: y))
            path.addLine(to: CGPoint(x: plot.maxX, y: y))
            path.setLineDash([2, 2], count: 2, phase: 0)
            path.lineWidth = 1
            UIColor.tertiaryLabel.setStroke()
            path.stroke()
        }

        for segment in content.segments where !segment.isEmpty {
            let points = segment.map(place)

            // 填充：让「多少」有体量感，不只是一根线
            if points.count > 1 {
                let area = UIBezierPath()
                area.move(to: CGPoint(x: points[0].x, y: plot.maxY))
                points.forEach { area.addLine(to: $0) }
                area.addLine(to: CGPoint(x: points[points.count - 1].x, y: plot.maxY))
                area.close()
                content.tint.withAlphaComponent(0.13).setFill()
                area.fill()
            }

            let line = UIBezierPath()
            line.move(to: points[0])
            points.dropFirst().forEach { line.addLine(to: $0) }
            line.lineWidth = 1.5
            line.lineJoinStyle = .round
            line.lineCapStyle = .round
            content.tint.withAlphaComponent(0.85).setStroke()
            line.stroke()
        }

        // 末点：一个实心小圆，指出「现在到这儿」
        guard let last = content.segments.last?.last else { return }
        let end = place(last)
        content.tint.setFill()
        UIBezierPath(ovalIn: CGRect(x: end.x - 1.5, y: end.y - 1.5, width: 3, height: 3)).fill()
    }
}
