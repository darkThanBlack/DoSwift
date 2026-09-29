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
        // 层级检查器用自己的 window：.alert - 1，压在业务窗口之上但在系统弹窗之下
        let window = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        window.rootViewController = HierarchyViewController()
        HierarchyHelper.shared.window = window
        window.show()
        // TODO: Hide DoSwift home window: DoraemonHomeWindow.shareInstance().hide()
    }
}
