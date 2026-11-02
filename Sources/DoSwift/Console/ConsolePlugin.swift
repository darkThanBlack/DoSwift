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

    /// The NSLog panel.
    ///
    /// Capture starts when the panel is opened. Everything logged before that moment is
    /// invisible — a pipe only sees what is written after it is attached. Call
    /// `start()` from `application(_:didFinishLaunchingWithOptions:)` if the panel
    /// should show the whole session instead.
    public final class ConsolePlugin: DO.DefaultPlugin {

        public static let shared = DO.ConsolePlugin()

        private init() {
            super.init(identifier: "nslog", title: "NSLog", icon: UIImage(systemName: "doc.text"))
        }

        private let list = DO.ConsoleViewController()

        /// Starts capturing stdout and stderr now, before the panel is ever opened.
        ///
        /// Opt-in on purpose: attaching the pipe takes over fd 1 and fd 2, so output stops
        /// going wherever it went before. Call it early in debug builds if you want history.
        public func start() {
            DO.ConsoleStore.shared.startCollecting()
        }

        public override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.refresh()

            DO.ConsoleStore.shared.startCollecting()

            DO.ConsoleStore.shared.unifiedLog.refresh()
        }

        public override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }
    }
}
