//
//  NSObject+Hierarchy.swift
//  DoSwift
//
//  Translated from NSObject+DoraemonHierarchy.m / .h
//  TODO: Fill in category model generation from UIView properties
//

import UIKit

// MARK: - NSObject Stub

extension NSObject {

    /// Hash-based color for border highlighting
    @objc var hierarchy_hashColor: UIColor {
        let hue = CGFloat(abs(hash) % 256) / 256.0
        return UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1)
    }

    var hierarchy_categoryModels: [HierarchyCategoryModel] {
        // TODO: Translate from doraemon_hierarchyCategoryModels
        []
    }

    // TODO: Translate the following alert methods
    @objc func hierarchy_showIntAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showFrameAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showColorAlertAndAutomicSet(keyPath: String) {}
    @objc func hierarchy_showFontAlertAndAutomicSet(keyPath: String) {}
}

// MARK: - UIView Stub

extension UIView {

    var hierarchy_sizeCategoryModels: [HierarchyCategoryModel] {
        // TODO: Translate from doraemon_sizeHierarchyCategoryModels
        []
    }
}
