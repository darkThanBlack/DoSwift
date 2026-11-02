//
//  NetworkPlugin.swift
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

    /// The "Network" tool. Capture is owned by `DO.NetworkCapture`; this only wraps a window.
    final class NetworkPlugin: DO.DefaultPlugin {

        static let shared = DO.NetworkPlugin()

        private init() {
            super.init(identifier: "network", title: "网络", icon: UIImage(systemName: "network"))
        }

        private lazy var list = DO.NetworkViewController()

        override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }

        override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.reload()
        }
    }
}
