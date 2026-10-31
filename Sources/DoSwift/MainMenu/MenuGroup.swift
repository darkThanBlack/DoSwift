//
//  MenuGroup.swift
//  DoSwift
//
//  Created by moonShadow on 2026/09/28
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    struct MenuGroup {

        let title: String

        var items: [DO.MenuItem]

        init(title: String, items: [DO.MenuItem]) {
            self.title = title
            self.items = items
        }
    }
}
