//
//  TrendPoint.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    struct TrendPoint {

        let t: TimeInterval
        let v: Double
    }
}

extension Array where Element == DO.TrendPoint {

    func segments(from: TimeInterval, to: TimeInterval, gap: TimeInterval) -> [ArraySlice<DO.TrendPoint>] {
        guard !isEmpty else { return [] }

        var lower = 0
        while lower < count, self[lower].t < from { lower += 1 }
        guard lower < count else { return [] }

        var upper = lower
        while upper < count, self[upper].t <= to { upper += 1 }
        guard lower < upper else { return [] }

        var result: [ArraySlice<DO.TrendPoint>] = []
        var start = lower
        for index in (lower + 1)..<upper where self[index].t - self[index - 1].t > gap {
            result.append(self[start..<index])
            start = index
        }
        result.append(self[start..<upper])
        return result
    }
}
