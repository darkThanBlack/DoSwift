//
//  HierarchyPlugin.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyPlugin.m / .h
//

import UIKit

public class HierarchyPlugin {
    
    public init() {}
    
    public func pluginDidLoad() {
        let window = HierarchyWindow(frame: UIScreen.main.bounds)
        HierarchyHelper.shared.window = window
        window.showWindow()
        window.backgroundColor = .red.withAlphaComponent(0.2)
        // TODO: Hide DoSwift home window: DoraemonHomeWindow.shareInstance().hide()
    }
}
