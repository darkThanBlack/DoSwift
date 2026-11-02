//
//  TrendPlotView.swift
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

    struct TrendPlotContent {

        let segments: [[CGPoint]]

        let threshold: Double?

        let tint: UIColor
    }

    @objc(DOTrendPlotView)
    final class TrendPlotView: UIView {

        private var content: DO.TrendPlotContent?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isOpaque = false
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(_ content: DO.TrendPlotContent?) {
            self.content = content
            setNeedsDisplay()
        }

        override func draw(_ rect: CGRect) {
            guard let content = content, bounds.width > 0, bounds.height > 0 else { return }

            let plot = bounds

            func place(_ point: CGPoint) -> CGPoint {
                CGPoint(
                    x: plot.minX + point.x * plot.width,
                    y: plot.maxY - point.y * plot.height
                )
            }

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

            guard let last = content.segments.last?.last else { return }
            let end = place(last)
            content.tint.setFill()
            UIBezierPath(ovalIn: CGRect(x: end.x - 1.5, y: end.y - 1.5, width: 3, height: 3)).fill()
        }
    }
}
