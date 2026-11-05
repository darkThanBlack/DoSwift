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
            super.init(identifier: "ui_hierarchy", title: DO.Text.Hierarchy.pluginTitle, icon: UIImage(systemName: "viewfinder"))
        }

        var appWindow: UIWindow? {
            DO.Core.shared.appWindow
        }

        var config: DO.HierarchyConfig = .load()

        /// The overlay is retained across shows, so the observation must be released here.
        private weak var root: DO.HierarchyViewController?

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: DO.Core.screenBounds, level: .alert - 1)
            let root = DO.HierarchyViewController()
            self.root = root
            w.rootViewController = root
            w.addNoResponseView(root.view)
            return w
        }

        override func show() {
            super.show()

            // Only when the view already exists: forcing an early load would run `viewDidLoad`
            // before the window has bounds and misplace the picker.
            guard root?.isViewLoaded == true else { return }
            root?.resumeSelection()
        }

        override func hide() {
            root?.stopObservingAll()
            super.hide()
        }
    }
}
