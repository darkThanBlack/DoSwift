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

    /// 面包屑的路径栈（纯逻辑，只认 id，不依赖 UIKit / ``DO.FileNode``）。值语义，栈里恒有根。
    struct FilePathStack: Equatable {

        /// 从根到当前层，恒非空
        private(set) var ids: [String]

        init(rootID: String) {
            self.ids = [rootID]
        }

        /// 深度（含根），最小 1
        var depth: Int { return ids.count }

        var rootID: String { return ids[0] }

        var topID: String { return ids[ids.count - 1] }

        func index(of id: String) -> Int? {
            return ids.firstIndex(of: id)
        }

        /// 追加一层；id 已在栈中则视为绕回来，先回退到该层（防环）。返回该层下标。
        @discardableResult
        mutating func push(_ id: String) -> Int {
            if let index = index(of: id) {
                ids.removeSubrange((index + 1)..<ids.count)
                return index
            }
            ids.append(id)
            return ids.count - 1
        }

        /// 保留前 depth 层（点面包屑）；越界一律 clamp 到根，不崩
        mutating func trim(toDepth depth: Int) {
            let count = max(1, min(depth, ids.count))
            ids.removeSubrange(count..<ids.count)
        }
    }
}
