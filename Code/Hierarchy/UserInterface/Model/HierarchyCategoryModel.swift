//
//  HierarchyCategoryModel.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    class HierarchyCategoryModel {
        let title: String?
        let items: [DO.HierarchyCellModel]

        init(title: String?, items: [DO.HierarchyCellModel]) {
            self.title = title
            self.items = items
        }
    }
}
