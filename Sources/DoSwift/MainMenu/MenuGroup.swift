//
//  DO.MenuGroup.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

extension DO {

    public struct MenuGroup {

        public let title: String

        public var items: [DO.MenuItem]

        public init(title: String, items: [DO.MenuItem]) {
            self.title = title
            self.items = items
        }
    }
}
