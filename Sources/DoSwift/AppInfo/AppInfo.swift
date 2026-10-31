//
//  AppInfo.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit
import QuickLook

extension DO {

    final class AppInfo {

        static let shared = DO.AppInfo()

        private let device = DO.AppInfoDevice()
        private let application = DO.AppInfoApplication()
        private let runtime = DO.AppInfoRuntime()
        private let authority = DO.AppInfoAuthority()

        var onChange: (() -> Void)?

        private init() {
            authority.onChange = { [weak self] in self?.onChange?() }
        }

        func reload() {
            device.reload()
            application.reload()
            runtime.reload()
            authority.reload()
        }

        func sections() -> [DO.AppInfoSection] {
            return [device.section(), application.section(), runtime.section(), authority.section()]
                .compactMap { $0 }
        }
    }
}
