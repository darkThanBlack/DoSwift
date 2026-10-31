//
//  DO.MenuItem.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

extension DO {

    public final class MenuItem: DO.Plugin {

        public let identifier: String

        public let title: String

        public var icon: UIImage?

        public var actionHandler: (() -> ())?

        public init(identifier: String, title: String, icon: UIImage? = nil, actionHandler: (() -> Void)? = nil) {
            self.identifier = identifier
            self.title = title
            self.icon = icon
            self.actionHandler = actionHandler
        }

        public convenience init(plugin: any DO.Plugin) {
            self.init(identifier: plugin.identifier, title: plugin.title, icon: plugin.icon, actionHandler: plugin.actionHandler)
        }
    }
}
