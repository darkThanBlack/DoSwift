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
    public final class NetworkPlugin: DO.DefaultPlugin {

        public static let shared = DO.NetworkPlugin()

        private init() {
            super.init(identifier: "network", title: DO.Text.Network.title, icon: UIImage(systemName: "network"))
        }

        private lazy var list = DO.NetworkViewController()

        /// Starts capture now. Opt-in on purpose: swizzling changes the process for everyone,
        /// so the host decides when. Opening the panel alone does not capture anything.
        public func start() {
            DO.NetworkCapture.shared.start()
        }

        public override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }

        public override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.reload()
        }
    }
}
