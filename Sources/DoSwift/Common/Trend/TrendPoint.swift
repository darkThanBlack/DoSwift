//
//  TrendPoint.swift
//  DoSwift
//

import Foundation

/// 曲线上的一个点：**时刻 + 一个纵坐标**。
///
/// 它**不是各指标存储类型的基类**——CPU、内存、帧率的原始记录形状都不一样
/// （累计时间 / 两个堆字段 / 帧率加慢帧计数），硬抽成一个会丢掉信息。
/// 它是**出口类型**：各源在自己的 `chart` 里把记录投影成它，view 只认识它。
struct TrendPoint {

    let t: TimeInterval
    let v: Double
}

extension Array where Element == TrendPoint {

    /// 取 `[from, to]` 内的点，**按连续性切成若干段**。
    ///
    /// 相邻两点间隔超过 `gap` 就断开。断档的判据属于数据层，「断开画」是 UI 的选择
    /// ——它拿到若干段，愿意连线就连，愿意留白就留白。
    func segments(from: TimeInterval, to: TimeInterval, gap: TimeInterval) -> [ArraySlice<TrendPoint>] {
        guard !isEmpty else { return [] }

        var lower = 0
        while lower < count, self[lower].t < from { lower += 1 }
        guard lower < count else { return [] }

        var upper = lower
        while upper < count, self[upper].t <= to { upper += 1 }
        guard lower < upper else { return [] }

        var result: [ArraySlice<TrendPoint>] = []
        var start = lower
        for index in (lower + 1)..<upper where self[index].t - self[index - 1].t > gap {
            result.append(self[start..<index])
            start = index
        }
        result.append(self[start..<upper])
        return result
    }
}
