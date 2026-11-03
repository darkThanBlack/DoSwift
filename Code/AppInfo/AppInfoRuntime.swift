//
//  AppInfoRuntime.swift
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

    final class AppInfoRuntime {

        private(set) var topViewController: String?
        private(set) var locale: String?
        private(set) var timeZone: String?
        private(set) var thermalState: String?
        private(set) var lowPowerMode: String?
        private(set) var vendorIdentifier: String?

        func reload() {
            topViewController = Self.topViewController()
            locale = Locale.current.identifier
            timeZone = Self.timeZone()
            thermalState = Self.thermalState()
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled ? DO.Text.AppInfo.enabled : DO.Text.AppInfo.disabled
            vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString
        }

        func section() -> DO.AppInfoSection? {
            return DO.AppInfoSectionBuilder.make(DO.Text.AppInfo.runtimeSection, [
                (DO.Text.AppInfo.rowTopViewController, topViewController),
                (DO.Text.AppInfo.rowLanguageAndRegion, locale),
                (DO.Text.AppInfo.rowTimeZone, timeZone),
                (DO.Text.AppInfo.rowThermalState, thermalState),
                (DO.Text.AppInfo.rowLowPowerMode, lowPowerMode),
                (DO.Text.AppInfo.rowVendorIdentifier, vendorIdentifier),
            ])
        }

        private static func topViewController() -> String? {
            guard let root = DO.Core.shared.appWindow?.rootViewController else { return nil }
            return String(describing: topmost(in: root))
        }

        private static func topmost(in controller: UIViewController) -> UIViewController {
            if let presented = controller.presentedViewController {
                return topmost(in: presented)
            }
            if let nav = controller as? UINavigationController, let visible = nav.visibleViewController {
                return topmost(in: visible)
            }
            if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
                return topmost(in: selected)
            }
            return controller
        }

        private static func timeZone() -> String {
            let zone = TimeZone.current
            let hours = zone.secondsFromGMT() / 3600
            return "\(zone.identifier) (UTC\(hours >= 0 ? "+" : "")\(hours))"
        }

        private static func thermalState() -> String {
            switch ProcessInfo.processInfo.thermalState {
            case .nominal:    return DO.Text.AppInfo.thermalNominal
            case .fair:       return DO.Text.AppInfo.thermalFair
            case .serious:    return DO.Text.AppInfo.thermalSerious
            case .critical:   return DO.Text.AppInfo.thermalCritical
            @unknown default: return DO.Text.AppInfo.thermalUnknown
            }
        }
    }
}
