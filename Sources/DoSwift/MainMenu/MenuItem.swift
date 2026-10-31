//
//  MenuItem.swift
//  DoSwift
//
//  Created by moonShadow on 2025/09/26
//  Copyright © 2025 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    final class MenuItem: DO.Plugin {

        let identifier: String

        let title: String

        let icon: UIImage?

        let actionHandler: (() -> ())?

        init(identifier: String, title: String, icon: UIImage? = nil, actionHandler: (() -> Void)? = nil) {
            self.identifier = identifier
            self.title = title
            self.icon = icon
            self.actionHandler = actionHandler
        }

        convenience init(plugin: any DO.Plugin) {
            self.init(identifier: plugin.identifier, title: plugin.title, icon: plugin.icon, actionHandler: plugin.actionHandler)
        }
    }
}
