//
//  DoSwiftMenuGroup.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

public struct DoSwiftMenuGroup {

    public let title: String

    public var items: [DoSwiftMenuItem]

    public init(title: String, items: [DoSwiftMenuItem]) {
        self.title = title
        self.items = items
    }
}
