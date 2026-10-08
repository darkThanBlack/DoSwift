//
//  HierarchyPlugin.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyPlugin.m / .h
//

import UIKit

/// Hierarchy 工具的唯一入口，同时保管这份工具自己的运行时状态
/// （原 `HierarchyHelper` 已并入此处，不再单独存在）。
public class HierarchyPlugin {

    public static let shared = HierarchyPlugin()

    private init() {}

    // MARK: - State

    /// 层级检查器自己的 window：.alert - 1，压在业务窗口之上但在系统弹窗之下
    var window: OverlayWindow?

    /// 业务 app 的主 window。由 `DoSwiftCore.start(appWindow:)` 注入，这里只做转发。
    var appWindow: UIWindow? {
        DoSwiftCore.shared.appWindow
    }

    /// 是否忽略私有类（类名以下划线开头）
    var isIgnorePrivateClass: Bool = false

    // MARK: - Lifecycle

    public func pluginDidLoad() {
        let window = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        window.rootViewController = HierarchyViewController()
        self.window = window
        window.show()
        // TODO: Hide DoSwift home window: DoraemonHomeWindow.shareInstance().hide()
    }
}
