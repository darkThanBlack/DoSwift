//
//  HierarchyPlugin.swift
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

    ///
    class HierarchyPlugin: DO.DefaultPlugin {

        static let shared = DO.HierarchyPlugin()

        private init() {
            super.init(identifier: "ui_hierarchy", title: "视图结构", icon: UIImage(systemName: "viewfinder"))
        }

        var appWindow: UIWindow? {
            DO.Core.shared.appWindow
        }

        var config: DO.HierarchyConfig = .load()

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            let root = DO.HierarchyViewController()
            w.rootViewController = root
            w.addNoResponseView(root.view)
            return w
        }
    }
}
