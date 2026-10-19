//
//  TrendChart.swift
//  DoSwift
//

import Foundation

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
