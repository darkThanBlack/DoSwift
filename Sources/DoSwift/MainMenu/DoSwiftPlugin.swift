//
//  DoSwiftPlugin.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/20.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 业务自定义插件。
///
/// 内建工具（App 信息 / UserDefaults / 性能 …）都是「一个工具一个 window、一套导航栈」。
/// 业务想加自己的调试页，此前唯一的办法是往 `start(items:)` 里塞一个带 `actionHandler`
/// 的菜单项——窗口、层级、导航栈、关闭按钮全得自己再写一遍，写错一处就是「点开没反应」
/// 或者「点开之后 App 点不动了」。
///
/// 实现这个协议交给 `start(appWindow:plugins:)`，上面那些都由 `DoSwiftPluginHost` 提供，
/// 业务只剩一件事：写那一页。
public protocol DoSwiftPlugin: AnyObject {

    /// 菜单项唯一标识。**与内建工具的 identifier 同处一个命名空间**，别重名。
    var identifier: String { get }

    /// 菜单项标题
    var title: String { get }

    /// 菜单项图标。默认 `globe`。
    var icon: UIImage? { get }

    /// 每次从菜单点开时调用，返回这一次要显示的页面。
    ///
    /// **每次现造**，不复用上一次那个：调试页读的都是「当下」的状态（当前环境、当前登录态、
    /// 当前页面 …），复用旧实例就得再约定一套刷新协议。
    ///
    /// - Parameter host: 承载这一页的宿主。页面做完该走的事（比如切完环境要退出登录）
    ///   用 `host.hide()` 收掉自己——这一层是全屏的，不收掉会盖住接下来的页面。
    func makeViewController(host: DoSwiftPluginHost) -> UIViewController
}

extension DoSwiftPlugin {

    /// 默认图标：`globe`。
    ///
    /// 取 iOS 13（SF Symbols 1）就存在的符号，与内建菜单同一口径；
    /// 可用性逐个核对过 `name_availability.plist` 的 `year == 2019`。
    public var icon: UIImage? {
        return UIImage(systemName: "globe")
    }
}
