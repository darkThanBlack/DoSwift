//
//  AppInfoApplication.swift
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

    final class AppInfoApplication {

        private(set) var bundleIdentifier: String?
        private(set) var version: String?
        private(set) var build: String?
        private(set) var displayName: String?
        private(set) var buildConfiguration: String?
        private(set) var distribution: String?
        private(set) var runtimeForm: String?
        private(set) var executableTimestamp: String?

        func reload() {
            bundleIdentifier = Self.bundleIdentifier()
            version = Self.infoString("CFBundleShortVersionString")
            build = Self.infoString("CFBundleVersion")
            displayName = Self.displayName()
            buildConfiguration = Self.buildConfiguration()
            distribution = Self.distribution()
            runtimeForm = Self.runtimeForm()
            executableTimestamp = Self.executableTimestamp()
        }

        func section() -> DO.AppInfoSection? {
            return DO.AppInfoSectionBuilder.make(DO.Text.AppInfo.applicationSection, [
                (DO.Text.AppInfo.rowBundleIdentifier, bundleIdentifier),
                (DO.Text.AppInfo.rowVersion, version),
                (DO.Text.AppInfo.rowBuild, build),
                (DO.Text.AppInfo.rowDisplayName, displayName),
                (DO.Text.AppInfo.rowBuildConfiguration, buildConfiguration),
                (DO.Text.AppInfo.rowDistribution, distribution),
                (DO.Text.AppInfo.rowRuntimeForm, runtimeForm),
                (DO.Text.AppInfo.rowExecutableTimestamp, executableTimestamp),
            ])
        }

        private static func bundleIdentifier() -> String? {
            Bundle.main.bundleIdentifier
        }

        private static func infoString(_ key: String) -> String? {
            Bundle.main.object(forInfoDictionaryKey: key) as? String
        }

        private static func displayName() -> String? {
            infoString("CFBundleDisplayName") ?? infoString("CFBundleName")
        }

        private static func buildConfiguration() -> String {
            #if DEBUG
            return "Debug"
            #else
            return "Release"
            #endif
        }

        private static func distribution() -> String {
            guard let receipt = Bundle.main.appStoreReceiptURL else { return DO.Text.AppInfo.developmentSigned }
            return receipt.lastPathComponent == "sandboxReceipt" ? "TestFlight" : "App Store"
        }

        private static func runtimeForm() -> String {
            #if targetEnvironment(simulator)
            return DO.Text.AppInfo.simulator
            #else
            if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
                return DO.Text.AppInfo.deviceOnMac
            }
            return DO.Text.AppInfo.device
            #endif
        }

        private static func executableTimestamp() -> String? {
            guard let url = Bundle.main.executableURL,
                  let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                  let date = values.contentModificationDate
            else { return nil }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }
}
