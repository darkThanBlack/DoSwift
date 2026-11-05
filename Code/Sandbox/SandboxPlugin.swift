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

    /// The "Sandbox" tool. Browsing is owned by `DO.SandboxViewController`; this only wraps a window.
    final class SandboxPlugin: DO.DefaultPlugin {

        static let shared = DO.SandboxPlugin()

        private init() {
            super.init(identifier: "sandbox", title: DO.Text.Sandbox.title, icon: UIImage(systemName: "folder"))
        }

        private let browser = DO.SandboxViewController()

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: DO.Core.screenBounds, level: .alert - 1)
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
