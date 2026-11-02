//
//  SandboxPlugin.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// The "Sandbox" tool. Browsing itself is owned by `DO.SandboxViewController`; this only
    /// puts a window around it.
    final class SandboxPlugin: DO.DefaultPlugin {

        static let shared = DO.SandboxPlugin()

        private init() {
            super.init(identifier: "sandbox", title: "沙盒", icon: UIImage(systemName: "folder"))
        }

        private let browser = DO.SandboxViewController()

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: browser)
            return w
        }

        override func show() {
            super.show()

            browser.navigationController?.popToRootViewController(animated: false)
            browser.reset()
        }
    }
}
