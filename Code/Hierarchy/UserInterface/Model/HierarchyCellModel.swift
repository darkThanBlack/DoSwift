//
//  HierarchyCellModel.swift
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

    class HierarchyCellModel {

        let title: String?
        let detailTitle: String?

        var separatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

        var edit: DO.HierarchyEditDescriptor?

        init(title: String?, detailTitle: String?) {
            self.title = title
            self.detailTitle = detailTitle
        }

        @discardableResult
        func noneInsets() -> DO.HierarchyCellModel {
            separatorInsets = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
            return self
        }
    }

}

extension DO.HierarchyCellModel: DO.KeyValueCellDataSource {

    var detail: String? {
        detailTitle
    }

    var rightImage: UIImage? {
        nil
    }
}
