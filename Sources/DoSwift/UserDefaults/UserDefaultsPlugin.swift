//
//  UserDefaultsPlugin.swift
//  DoSwift
//

import UIKit

/// UserDefaults 浏览器的入口，同时保管它自己的 window。
///
/// 与 `HierarchyPlugin` 同构（每个工具一个 window，互不共用），**唯一的差别是不登记任何
/// `noResponseView`**：层级工具是「在业务 app 之上瞄一眼」，触摸必须透下去；这个工具要改
/// UserDefaults，触摸漏到业务 app 上就成了 bug。
public class UserDefaultsPlugin {

    public static let shared = UserDefaultsPlugin()

    private init() {}

    // MARK: - State

    /// .alert - 1：压在业务窗口之上、系统弹窗之下
    private(set) var window: OverlayWindow?

    private let list = UserDefaultsViewController()

    private lazy var nav = UINavigationController(rootViewController: list)

    // MARK: - Public Interface

    /// 显示浏览器
    public func show() {
        prepare()

        // 窗口是复用的，上一次退出时的局面（停在详情页、还在编辑态、搜索框里还有字）
        // 不该带到这一次来
        nav.popToRootViewController(animated: false)
        list.refresh()

        window?.isHidden = false
    }

    /// 隐藏浏览器
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
