//
//  NSObject+Hierarchy.swift
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

}

extension NSObject {

    /// Hash-based color for border highlighting
    @objc var hierarchy_hashColor: UIColor {
        let hue = CGFloat(abs(hash) % 256) / 256.0
        return UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1)
    }

    var hierarchy_categoryModels: [DO.HierarchyCategoryModel] {
        // TODO: Translate from doraemon_hierarchyCategoryModels
        []
    }

    // TODO: Translate the following alert methods
    @objc func hierarchy_showIntAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showFrameAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showColorAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showFontAlertAndAutomicSet(keyPath: String) {}
}

extension UIView {

    var hierarchy_sizeCategoryModels: [DO.HierarchyCategoryModel] {
        // TODO: Translate from doraemon_sizeHierarchyCategoryModels
        []
    }
}
