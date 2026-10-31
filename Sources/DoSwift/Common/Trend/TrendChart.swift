//
//  TrendChart.swift
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

    enum TrendThreshold {
        case above(Double)
        case below(Double)

        var value: Double {
            switch self {
            case .above(let value), .below(let value): return value
            }
        }
    }

    struct TrendChart {

        let title: String
        let unit: String
        let range: ClosedRange<Double>
        let threshold: DO.TrendThreshold?

        let interval: TimeInterval

        let tint: UIColor

        let points: [DO.TrendPoint]

        var latest: DO.TrendPoint? { points.last }
    }

}

extension DO.TrendChart {

    func isStale(at now: TimeInterval) -> Bool {
        guard let latest = latest else { return true }
        return now - latest.t > interval * 3
    }

    func isAlarming(at now: TimeInterval) -> Bool {
        guard let threshold = threshold, let latest = latest, !isStale(at: now) else { return false }
        switch threshold {
        case .above(let value): return latest.v > value
        case .below(let value): return latest.v < value
        }
    }

    func valueText(at now: TimeInterval) -> String {
        guard let latest = latest, now - latest.t <= interval * 3 else { return "—" }
        return String(Int(latest.v.rounded()))
    }
}

extension DO.TrendChart {

    func plotContent(
        for size: CGSize,
        window: ClosedRange<TimeInterval>,
        tint: UIColor? = nil
    ) -> DO.TrendPlotContent {
        let lower = window.lowerBound
        let length = max(window.upperBound - lower, .ulpOfOne)

        let inWindow = points.segments(from: lower, to: window.upperBound, gap: 0)
        let count = inWindow.reduce(0) { $0 + $1.count }

        let stride = max(1, count / max(Int(size.width.rounded()), 1))

        let gap = interval * Double(stride) * 2

        let valueLower = range.lowerBound
        let valueSpan = max(range.upperBound - valueLower, .ulpOfOne)

        var segments: [[CGPoint]] = []
        for slice in inWindow {
            var sampled: [DO.TrendPoint] = []
            var cursor = slice.startIndex
            while cursor < slice.endIndex {
                sampled.append(slice[cursor])
                cursor += stride
            }
            guard !sampled.isEmpty else { continue }

            var current: [CGPoint] = []
            var previous: TimeInterval = 0
            for point in sampled {
                if !current.isEmpty, point.t - previous > gap {
                    segments.append(current)
                    current = []
                }
                current.append(
                    CGPoint(
                        x: min(max((point.t - lower) / length, 0), 1),
                        y: min(max((point.v - valueLower) / valueSpan, 0), 1)
                    )
                )
                previous = point.t
            }
            if !current.isEmpty { segments.append(current) }
        }

        var normalizedThreshold: Double?
        if let threshold = threshold, range.contains(threshold.value) {
            normalizedThreshold = min(max((threshold.value - valueLower) / valueSpan, 0), 1)
        }

        return DO.TrendPlotContent(
            segments: segments,
            threshold: normalizedThreshold,
            tint: tint ?? self.tint
        )
    }
}
