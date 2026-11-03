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
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled ? "开启" : "关闭"
            vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString
        }

        func section() -> DO.AppInfoSection? {
            return DO.AppInfoSectionBuilder.make("运行时", [
                ("当前页面", topViewController),
                ("语言与地区", locale),
                ("时区", timeZone),
                ("热状态", thermalState),
                ("低电量模式", lowPowerMode),
                ("设备标识", vendorIdentifier),
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
            case .nominal:    return "正常"
            case .fair:       return "偏热"
            case .serious:    return "严重"
            case .critical:   return "危急"
            @unknown default: return "未知"
            }
        }
    }
}
