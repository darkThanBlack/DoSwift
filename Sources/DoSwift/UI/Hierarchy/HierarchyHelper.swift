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
