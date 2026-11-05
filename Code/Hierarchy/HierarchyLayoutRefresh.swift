//
//  HierarchyLayoutRefresh.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/05
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// The pass every runtime edit ends with. Property writes and constraint writes share it,
    /// so "modified" and "laid out" stay one step, exactly like the hand-written edits did.
    enum HierarchyLayoutRefresh {

        static func refresh(_ view: UIView) {
            view.setNeedsLayout()
            view.invalidateIntrinsicContentSize()
            view.window?.layoutIfNeeded()
        }
    }
}
