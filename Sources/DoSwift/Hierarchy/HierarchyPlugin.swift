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
    private(set) var window: OverlayWindow?

    /// 业务 app 的主 window。由 `DoSwiftCore.start(appWindow:)` 注入，这里只做转发。
    var appWindow: UIWindow? {
        DoSwiftCore.shared.appWindow
    }

    /// 是否忽略私有类（类名以下划线开头）
    var isIgnorePrivateClass: Bool = true

    /// 是否显示对齐标尺（标线 + 信息面板里的 Position 行）
    var isAlignRulerEnabled: Bool = true

    // MARK: - Public Interface

    /// 显示层级检查器
    public func show() {
        prepare()
        window?.isHidden = false
    }

    /// 隐藏层级检查器
    public func hide() {
        window?.isHidden = true
    }

    // MARK: - Private

    private func prepare() {
        guard window == nil else { return }

        // Scene 绑定由 OverlayWindow 自己处理（按前台活跃状态过滤）
        let overlayWindow = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        overlayWindow.isHidden = true
        let root = HierarchyViewController()
        overlayWindow.rootViewController = root
        window = overlayWindow
        
        overlayWindow.addNoResponseView(root.view)
    }
}
