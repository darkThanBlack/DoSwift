//
//  Core.swift
//  DoSwift
//
//  Created by moonShadow on 2025/09/26
//  Copyright © 2025 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    public final class Core {

        public static let shared = DO.Core()
        private init() {}

        /// Your APP's window
        private(set) weak var appWindow: UIWindow?

        /// DoSwift main menu drift handle
        public private(set) var window: DO.OverlayWindow?

        public func start(
            appWindow: UIWindow?,
            plugins: [DO.Plugin] = []
        ) {
            self.appWindow = appWindow

            self.menuGroups = defMenuGroups
            let customGroup = DO.MenuGroup(
                title: "自定义",
                items: plugins.map({ DO.MenuItem(plugin: $0) })
            )
            if customGroup.items.isEmpty == false {
                menuGroups.append(customGroup)
            }

            show()
        }

        public func show() {
            prepare()
            window?.isHidden = false
        }

        public func hide() {
            window?.isHidden = true
        }

        private lazy var menuGroups: [DO.MenuGroup] = []

        private lazy var defMenuGroups: [DO.MenuGroup] = {

            func item(_ id: String, _ title: String, _ symbol: String) -> DO.MenuItem {
                return DO.MenuItem(identifier: id, title: title, icon: UIImage(systemName: symbol))
            }

            let common = DO.MenuGroup(title: "常用工具", items: [
                item("app_setting",    "应用设置",      "gear"),
                DO.MenuItem(plugin: DO.AppInfoPlugin.shared),
                item("sandbox",        "沙盒浏览器",    "folder"),
                item("mock_gps",       "Mock GPS",      "location"),
                item("h5",             "H5任意门",      "safari"),
                item("clean_cache",    "清理缓存",      "trash"),
                DO.MenuItem(plugin: DO.ConsolePlugin.shared),
                item("db_view",        "DBView",        "archivebox"),
                DO.MenuItem(plugin: DO.UserDefaultsPlugin.shared),
                item("js_script",      "JS脚本",        "chevron.left.slash.chevron.right"),
            ])

            let performance = DO.MenuGroup(title: "性能", items: [
                DO.MenuItem(plugin: DO.PerfTrendPlugin.shared),
            ])

            let visual = DO.MenuGroup(title: "视觉工具", items: [
                DO.MenuItem(plugin: DO.HierarchyPlugin.shared),
            ])

            return [visual, performance, common]
        }()

        private func prepare() {
            guard window == nil else { return }

            let overlayWindow = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .statusBar)
            overlayWindow.isHidden = true
            overlayWindow.backgroundColor = .clear

            let root = DO.MainViewController()
            root.menuGroups = menuGroups
            overlayWindow.rootViewController = root

            window = overlayWindow

            overlayWindow.addNoResponseView(root.view)
        }

    }
}
