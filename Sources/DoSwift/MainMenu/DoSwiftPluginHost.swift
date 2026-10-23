//
//  DoSwiftPluginHost.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/20.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 业务自定义插件的宿主：一个插件一个 window、一套导航栈。
///
/// 形态与内建工具（`AppInfoPlugin` / `UserDefaultsPlugin` / `ConsolePlugin` …）完全一致：
/// 窗口压在业务窗口之上、系统弹窗之下（`.alert - 1`），**不登记 `noResponseView`**
/// ——插件的页面是要点的，触摸漏到业务 App 上就成了 bug。
///
/// 由 `DoSwiftCore` 创建并持有，业务不自己造，只从 `makeViewController(host:)` 拿到它、
/// 在自己做完事之后调 `hide()`。
public final class DoSwiftPluginHost {

    // MARK: - Properties

    public let plugin: DoSwiftPlugin

    /// 复用同一个窗口：反复开关不走 window 的创建/销毁，与内建工具一致
    private(set) var window: OverlayWindow?

    private let navigator = UINavigationController()

    // MARK: - Init

    init(plugin: DoSwiftPlugin) {
        self.plugin = plugin
    }

    // MARK: - Public Interface

    /// 显示插件页面。**每次都向插件要一个新页面**，上一次停留的状态不带到这一次来。
    public func show() {
        prepare()

        let page = plugin.makeViewController(host: self)

        // 页面没给自己的关闭入口时补一个。这一层是全屏的，没有返回也没有关闭按钮就出不去；
        // 自己给了就不动——有的页面要「关闭前先确认」，那套按钮不该被这里顶掉。
        if page.navigationItem.leftBarButtonItem == nil, page.navigationItem.leftBarButtonItems == nil {
            page.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(close)
            )
        }

        navigator.setViewControllers([page], animated: false)
        window?.isHidden = false
    }

    /// 隐藏。插件页面里做完了事（切完环境、保存成功 …）走这里。
    public func hide() {
        window?.isHidden = true
    }

    // MARK: - Private

    private func prepare() {
        guard window == nil else { return }

        // 场景由 OverlayWindow 初始化时绑定；压在业务窗口之上、弹窗之下
        let overlay = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        overlay.isHidden = true
        overlay.rootViewController = navigator
        window = overlay
    }

    @objc private func close() {
        hide()
    }
}
