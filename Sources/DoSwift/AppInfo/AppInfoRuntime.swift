//
//  AppInfoRuntime.swift
//  DoSwift
//

import UIKit

/// 「运行时」组：此刻这个进程与这台设备的运行状态。
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

    func section() -> DoSwiftAppInfoSection? {
        return AppInfoSection.make("运行时", [
            ("当前页面", topViewController),
            ("语言与地区", locale),
            ("时区", timeZone),
            ("热状态", thermalState),
            ("低电量模式", lowPowerMode),
            ("设备标识", vendorIdentifier),
        ])
    }

    // MARK: - 取值

    /// 业务 App 此刻最顶上那个控制器。
    ///
    /// 从 `DoSwiftCore.appWindow` 往下找，而**不是**从 `UIApplication` 找：后者会把
    /// DoSwift 自己的浮窗和本面板一并算进去，答出来的就成了「调试工具停在哪一页」
    /// ——那正是这个字段要回答的反面。
    private static func topViewController() -> String? {
        guard let root = DoSwiftCore.shared.appWindow?.rootViewController else { return nil }
        return String(describing: topmost(in: root))
    }

    /// 从容器往下钻到真正的叶子控制器。
    ///
    /// 先看 `presentedViewController`：present 出来的那一层永远压在最上面
    /// （`UINavigationController` 的 `visibleViewController`、`UITabBarController` 的
    /// `selectedViewController` 都会把这一维漏掉）。
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

    /// 时区标识与相对 UTC 的偏移。
    private static func timeZone() -> String {
        let zone = TimeZone.current
        let hours = zone.secondsFromGMT() / 3600
        return "\(zone.identifier) (UTC\(hours >= 0 ? "+" : "")\(hours))"
    }

    /// 热状态。设备发烫时系统会降频，性能问题常常要从这里找原因。
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
