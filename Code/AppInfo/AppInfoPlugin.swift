//
//  AppInfoPlugin.swift
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
    public class AppInfoPlugin: DO.DefaultPlugin {

        public static let shared = DO.AppInfoPlugin()

        private init() {
            super.init(identifier: "app_info", title: DO.Text.AppInfo.title, icon: UIImage(systemName: "info.circle"))
        }

        public override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.refresh()
        }

        public override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: DO.Core.screenBounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }

        private let list = DO.AppInfoViewController()

        public func setCustomItems(_ rows: [DO.AppInfoRow]) {
            list.customRows = rows
        }
    }
}
