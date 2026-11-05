//
//  PerfHistory.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/04
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// Fixed ceiling for the perf sources' history. At 10 Hz this keeps roughly 30 minutes;
    /// trend views and the report only read a window, so older points are dead weight that
    /// would otherwise grow for the whole session.
    enum PerfHistory {

        static let capacity = 18_000

        /// Trimming a whole buffer on every sample would shift ~18k elements at 10 Hz, so the
        /// drop happens once the slack is full; the array stays within `capacity + slack`.
        private static let slack = capacity / 10

        static func trim<T>(_ items: inout [T]) {
            guard items.count > capacity + slack else { return }
            items.removeFirst(items.count - capacity)
        }
    }
}
