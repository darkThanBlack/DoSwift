//
//  FilePathStack.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// Breadcrumb stack: pure logic over ids, value semantics, always rooted.
    struct FilePathStack: Equatable {

        /// Root to current; never empty.
        private(set) var ids: [String]

        init(rootID: String) {
            self.ids = [rootID]
        }

        /// Depth including the root; at least 1.
        var depth: Int { return ids.count }

        var rootID: String { return ids[0] }

        var topID: String { return ids[ids.count - 1] }

        func index(of id: String) -> Int? {
            return ids.firstIndex(of: id)
        }

        /// Push one level; an id already in the stack means a cycle, so trim back to it first.
        @discardableResult
        mutating func push(_ id: String) -> Int {
            if let index = index(of: id) {
                ids.removeSubrange((index + 1)..<ids.count)
                return index
            }
            ids.append(id)
            return ids.count - 1
        }

        /// Keep the first `depth` levels; out-of-range clamps to the root.
        mutating func trim(toDepth depth: Int) {
            let count = max(1, min(depth, ids.count))
            ids.removeSubrange(count..<ids.count)
        }
    }
}
