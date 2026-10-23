//
//  TrendChart.swift
//  DoSwift
//

import UIKit

/// 阈值线的位置**和方向**。
///
/// 方向不是装饰：CPU、内存是「超过就坏」，帧率是「低于就坏」。只给一个数的话，
/// 判方向的那一处一定会写死成 `>`，然后在帧率上悄悄判反。
enum TrendThreshold {
    case above(Double)
    case below(Double)

    var value: Double {
        switch self {
        case .above(let value), .below(let value): return value
        }
    }
}

/// **给 view 的唯一输入**：一条曲线要知道的全部东西。
///
/// 由 plugin 直接字面量构造——标题、单位、量程、阈值都是展示参数，归 UI 层；
/// 数据层只提供 `interval` 和 `points` 这两样它自己真正用得上的东西。
struct TrendChart {

    let title: String
    let unit: String
    let range: ClosedRange<Double>
    let threshold: TrendThreshold?

    /// 采样间隔。view 用它推断档（1.5 倍）与陈旧（3 倍）两条判据，
    /// 各源间隔不同，所以这两个数不能是全局常量。
    let interval: TimeInterval

    /// 这条曲线的身份色。**跟着指标走，不跟位置走**——视图顺序一变颜色就该不变。
    let tint: UIColor

    let points: [TrendPoint]

    var latest: TrendPoint? { points.last }
}

// MARK: - 读法

/// 「这个值现在还能不能代表现在」这类判断只有一份，header 和 plot 共用。
extension TrendChart {

    /// 最后一点比现在老过三个采样间隔，就当数据陈旧。
    ///
    /// 断档之后序列里不再有新点，而数值会一直挂着旧值——那是在拿几分钟前的读数
    /// 冒充现在。容忍度跟着源自己的采样间隔走，慢源不会被误判。
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

// MARK: - 归一化

/// 把一条曲线换算成**绘制层认识的东西**：归一化坐标 + 归一化阈值。
///
/// 工作全在业务层，`TrendPlotView` 只负责把 0…1 乘上自己的宽高。这条线划在这儿，
/// 是因为抽稀要知道画多宽、切段要知道采样间隔——都是绘制层拿不到的信息。
extension TrendChart {

    /// - Parameters:
    ///   - size: 只用来定抽稀步长（一个绘制点至少占 1pt）
    ///   - window: 横轴域
    ///   - tint: 覆盖曲线颜色。浮窗用它做告警变红；nil 用指标身份色
    func plotContent(
        for size: CGSize,
        window: ClosedRange<TimeInterval>,
        tint: UIColor? = nil
    ) -> TrendPlotContent {
        let lower = window.lowerBound
        let length = max(window.upperBound - lower, .ulpOfOne)

        // 先只取窗口内的点，gap 传 0 表示这里不分段——分段要等抽稀之后，
        // 因为断档阈值得跟着抽稀步长放大
        let inWindow = points.segments(from: lower, to: window.upperBound, gap: 0)
        let count = inWindow.reduce(0) { $0 + $1.count }

        // 一屏几千个点时按步长抽稀：每像素最多一个点。
        // 这一步必须在归一化之前，它决定要漏掉多少点
        let stride = max(1, count / max(Int(size.width.rounded()), 1))

        // 抽稀后相邻两个绘制点本来就在时间上隔了 stride 个采样，
        // 断档阈值必须跟着放大，否则每一段都会被当成断档而不连
        let gap = interval * Double(stride) * 2

        let valueLower = range.lowerBound
        let valueSpan = max(range.upperBound - valueLower, .ulpOfOne)

        var segments: [[CGPoint]] = []
        for slice in inWindow {
            var sampled: [TrendPoint] = []
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

        // 阈值落在量程外就不画：那条线会贴在边框上，看起来像是量程的一部分
        var normalizedThreshold: Double?
        if let threshold = threshold, range.contains(threshold.value) {
            normalizedThreshold = min(max((threshold.value - valueLower) / valueSpan, 0), 1)
        }

        return TrendPlotContent(
            segments: segments,
            threshold: normalizedThreshold,
            tint: tint ?? self.tint
        )
    }
}
