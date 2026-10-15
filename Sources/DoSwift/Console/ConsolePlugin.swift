//
//  ConsolePlugin.swift
//  DoSwift
//

import UIKit

/// 控制台的入口，同时保管它自己的 window。
///
/// 与 `HierarchyPlugin` / `UserDefaultsPlugin` 同构（每个工具一个 window，互不共用），
/// **不管登记 `noResponseView`**：控制台是拿来读的东西，触摸漏到业务 App 上不会读错数据
/// ——这一条与 UserDefaults 那页不同（那里要改存储，漏下去就是 bug）。
public class ConsolePlugin {

    public static let shared = ConsolePlugin()

    private init() {}

    // MARK: - State

    /// .alert - 1：压在业务窗口之上、系统弹窗之下
    private(set) var window: OverlayWindow?

    private let list = ConsoleViewController()

    private lazy var nav = UINavigationController(rootViewController: list)

    // MARK: - Public Interface

    public func show() {
        prepare()

        // 窗口是复用的，上一次退出时的局面（停在详情页、搜索框里还有字）不该带过来
        nav.popToRootViewController(animated: false)
        list.refresh()

        // fd 那条链路：**幂等**，只在第一次打开时真的接管，之后一直挂着。
        // 日志是「先打几条，再打开工具看」的用法，接管一关就等于把这段时间的日志丢了。
        ConsoleStore.shared.startCollecting()

        // 统一日志那条：**一次查询恒定约 1 秒**（见 `ConsoleUnifiedLog` 文件头），
        // 所以只能按需查。开页面查一次，之后由页面底部那颗按钮决定。
        // 不查也不会丢内容——续读游标留着，下一次查会把这段断档全捞回来。
        ConsoleStore.shared.unifiedLog.refresh()

        window?.isHidden = false
    }

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
