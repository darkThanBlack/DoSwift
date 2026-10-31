//
//  SectionCell.swift
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

    protocol SectionCellDelegate: AnyObject {

        func sectionCellDidTrigger(_ cell: UITableViewCell)
    }

    protocol SectionCell: AnyObject {

        var sectionDelegate: DO.SectionCellDelegate? { get set }
    }
}
