//
//  HierarchyHelper.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyHelper.m
//

import UIKit

class HierarchyHelper {
    static let shared = HierarchyHelper()

    var window: HierarchyWindow?

    /// 业务 app 的主窗口（由 `DoSwiftCore.start(appWindow:)` 注入，weak 持有）。
    /// Hierarchy 的拾取与坐标换算以此为基准，区别于本模块的遮罩 `window`。
    /// TODO: 后续补充 DTBKit 风格的默认搜索作为兜底。
    var businessWindow: UIWindow? {
        DoSwiftCore.shared.appWindow
    }

    /// 是否忽略私有类（类名以下划线开头）
    var isIgnorePrivateClass: Bool = false

    /// 获取所有窗口，按 windowLevel 排序
    func allWindows() -> [UIWindow] {
        allWindowsIgnorePrefix(nil)
    }

    /// 获取所有窗口，排除类名前缀匹配的窗口
    func allWindowsIgnorePrefix(_ prefix: String?) -> [UIWindow] {
        // TODO: ObjC NSInvocation 调用 allWindowsIncludingInternalWindows:onlyVisibleWindows:
        // Swift 不支持 NSInvocation，需通过 HierarchyWindowBridge 桥接
        var windows: [UIWindow] = []

        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    windows.append(contentsOf: windowScene.windows)
                }
            }
        }

        windows.sort { $0.windowLevel < $1.windowLevel }

        if let prefix = prefix, !prefix.isEmpty {
            windows = windows.filter { window in
                let className = String(describing: type(of: window))
                return !className.hasPrefix(prefix)
            }
        }

        return windows
    }
}
