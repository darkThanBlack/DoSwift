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

    /// The console panel. The pipe only sees what is written after it attaches, so call `start()`
    /// at launch if the panel should carry the whole session.
    public final class ConsolePlugin: DO.DefaultPlugin {

        public static let shared = DO.ConsolePlugin()

        private init() {
            super.init(identifier: "nslog", title: "Console", icon: UIImage(systemName: "doc.text"))
        }

        private let list = DO.ConsoleViewController()

        /// Attaches the pipe now. Opt-in: it takes over fd 1 and fd 2, so output stops going
        /// wherever it went before. Opening the panel alone does not start it.
        public func start() {
            DO.ConsoleStore.shared.startCollecting()
        }

        public override func show() {
            super.show()

            list.navigationController?.popToRootViewController(animated: false)
            list.refresh()

            DO.ConsoleStore.shared.unifiedLog.refresh()
        }

        public override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: DO.Core.screenBounds, level: .alert - 1)
            w.rootViewController = UINavigationController(rootViewController: list)
            return w
        }
    }
}
