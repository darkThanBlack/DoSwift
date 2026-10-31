//
//  ConsolePlugin.swift
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
    class ConsolePlugin: DO.DefaultPlugin {

        static let shared = DO.ConsolePlugin()

        private init() {
            super.init(identifier: "nslog", title: "NSLog", icon: UIImage(systemName: "doc.text"))
        }

        private let list = DO.ConsoleViewController()

        override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.refresh()

            DO.ConsoleStore.shared.startCollecting()

            DO.ConsoleStore.shared.unifiedLog.refresh()
        }

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }
    }
}
