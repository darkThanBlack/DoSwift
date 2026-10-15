//
//  AppInfoApplication.swift
//  DoSwift
//

import UIKit

/// 「应用」组：这个包是什么、怎么编出来的、跑的哪一份。
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

    func section() -> DoSwiftAppInfoSection? {
        return AppInfoSection.make("应用", [
            ("Bundle ID", bundleIdentifier),
            ("Version", version),
            ("Build", build),
            ("显示名", displayName),
            ("构建配置", buildConfiguration),
            ("分发渠道", distribution),
            ("运行形态", runtimeForm),
            ("可执行文件时间", executableTimestamp),
        ])
    }

    // MARK: - 取值

    private static func bundleIdentifier() -> String? {
        Bundle.main.bundleIdentifier
    }

    /// 营销版本号（`CFBundleShortVersionString`）。
    ///
    /// 原版 DoKit 把这一项挂在标题「VersionCode」下、把构建号挂在「Version」下
    /// ——两个标题和值正好对调了。这里按约定来。
    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    /// 桌面图标下面那个名字。`CFBundleDisplayName` 没配时系统用 `CFBundleName`。
    private static func displayName() -> String? {
        infoString("CFBundleDisplayName") ?? infoString("CFBundleName")
    }

    /// 这一份二进制是 Debug 还是 Release 编出来的。
    ///
    /// 编译期定，运行时推不出来——而这恰好是最常被问的一句「你装的是哪个包」。
    private static func buildConfiguration() -> String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    /// 分发渠道。判据是收据文件的**文件名**：
    /// `sandboxReceipt` = 沙盒环境（TestFlight 与本地商店环境都是它），
    /// `receipt` = App Store，**没有收据** = 开发签名或企业签名。
    private static func distribution() -> String {
        guard let receipt = Bundle.main.appStoreReceiptURL else { return "开发 / 企业签名" }
        return receipt.lastPathComponent == "sandboxReceipt" ? "TestFlight" : "App Store"
    }

    /// 跑在什么上。模拟器与真机是编译期就知道的，Mac 上跑要问运行时。
    private static func runtimeForm() -> String {
        #if targetEnvironment(simulator)
        return "模拟器"
        #else
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return "真机 · Mac"
        }
        return "真机"
        #endif
    }

    /// 可执行文件的时间戳。
    ///
    /// 名字刻意**不叫「构建时间」**：本地构建时它确实是链接那一刻，但经过商店重打包
    /// （签名、切片）之后会变成别的时刻，说是构建时间就成了假的。它的用处是回答
    /// 「手上这个包是哪一版」，而不是「它什么时候编的」。
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
