//
//  UserDefaultsPlugin.swift
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
    class UserDefaultsPlugin: DO.DefaultPlugin {

        static let shared = DO.UserDefaultsPlugin()

        private init() {
            super.init(identifier: "user_defaults", title: DO.Text.UserDefaults.title, icon: UIImage(systemName: "rectangle.grid.2x2"))
        }

        private let list = DO.UserDefaultsViewController()

        override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.refresh()
        }

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: DO.Core.screenBounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }
    }
}
