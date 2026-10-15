//
//  AppInfoPlugin.swift
//  DoSwift
//

import UIKit

/// 「App 信息」的入口，同时保管它自己的 window。
///
/// 与 `UserDefaultsPlugin` / `ConsolePlugin` 同构（每个工具一个 window，互不共用），
/// **不登记 `noResponseView`**：这一页只读，触摸漏到业务 App 上不会读错数据。
public class AppInfoPlugin {

    public static let shared = AppInfoPlugin()

    private init() {}

    // MARK: - State

    /// .alert - 1：压在业务窗口之上、系统弹窗之下
    private(set) var window: OverlayWindow?

    private let list = AppInfoViewController()

    private lazy var nav = UINavigationController(rootViewController: list)

    // MARK: - Public Interface

    /// 登记宿主自己的字段，显示在内建四组之后的「自定义」段里。
    ///
    /// 内建四组只放**库自己能算出来**的东西（设备、包、进程、权限）。环境域名、推送
    /// regid、公共参数这类只有宿主知道的，走这个入口。
    ///
    /// 只收值，不收闭包：这里进来的都是宿主**当场就能答上来**的东西，页面每次打开会重新读
    /// 这个数组，所以宿主换了值只要重新调一次本方法即可，不需要什么刷新协议。
    /// 整体替换，重复调用以最后一次为准。
    public func setCustomItems(_ rows: [DoSwiftAppInfoRow]) {
        list.customRows = rows
    }

    /// 显示面板
    public func show() {
        prepare()

        // 窗口是复用的，上一次退出时的局面（停在全文页、看到的是旧值）不该带到这一次来
        nav.popToRootViewController(animated: false)
        list.refresh()

        window?.isHidden = false
    }

    /// 隐藏面板
    public func hide() {
        window?.isHidden = true
    }

    // MARK: - Private

    private func prepare() {
        guard window == nil else { return }

        // Scene 绑定由 OverlayWindow 自己处理
        let overlayWindow = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        overlayWindow.isHidden = true
        overlayWindow.rootViewController = nav
        window = overlayWindow
    }
}
