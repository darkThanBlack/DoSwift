//
//  HierarchyPlugin.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyPlugin.m / .h
//

import UIKit

///
public class HierarchyPlugin: DoSwiftDefaultPlugin {
    
    public static let shared = HierarchyPlugin()
    
    private init() {
        super.init(identifier: "ui_hierarchy", title: "视图结构", icon: UIImage(systemName: "viewfinder"))
    }
    
    var appWindow: UIWindow? {
        DoSwiftCore.shared.appWindow
    }
    
    var config: HierarchyConfig = .load()
    
    public override func makeWindow() -> OverlayWindow {
        let w = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        let root = HierarchyViewController()
        w.rootViewController = root
        w.addNoResponseView(root.view)
        return w
    }
}
