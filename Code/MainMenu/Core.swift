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

    public final class Core: DefaultPlugin {

        public static let shared = DO.Core()
        private init() {
            super.init(identifier: "main", title: "", icon: nil)  // Meaningless
        }
        
        /// Your APP's window.
        private(set) weak var appWindow: UIWindow?
        
        /// It is strongly recommended to pass in an accurate window. Automated get app window can never be guaranteed to be 100% accurate.
        public func setup(
            appWindow: UIWindow?,
            plugins: [DO.Plugin] = []
        ) {
            guard let w = appWindow ?? keyWindow() else {
                assertionFailure("appWindow is nil")
                return
            }
            
            self.appWindow = w
            
            self.menuGroups = defMenuGroups
            let customGroup = DO.MenuGroup(
                title: "Custom",
                items: plugins.map({ DO.MenuItem(plugin: $0) })
            )
            if customGroup.items.isEmpty == false {
                menuGroups.insert(customGroup, at: 0)
            }
            
            show()
        }
        
        public override func makeWindow() -> DO.OverlayWindow {
            let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .statusBar)
            let root = DO.MainViewController()
            root.menuGroups = menuGroups
            w.rootViewController = root
            w.addNoResponseView(root.view)
            return w
        }
        
        /// Current scene in general — [best practices](https://darkthanblack.github.io/blogs/04-bp-keywindow)
        /// [refer](https://stackoverflow.com/questions/57134259)
        @available(iOS 13.0, *)
        private func keyWindowScene() -> UIWindowScene? {
            return UIApplication
                .shared
                .connectedScenes
                .compactMap({ ($0 as? UIWindowScene) })
                .first
        }
        
        /// Current window in general for nonscene-based app — [best practices](https://darkthanblack.github.io/blogs/04-bp-keywindow)
        /// [refer](https://stackoverflow.com/questions/57134259)
        private func keyWindow() -> UIWindow? {
            
            func style3() -> UIWindow? {
                if #available(iOS 15.0, *) {
                    return keyWindowScene()?.keyWindow
                }
                return nil
            }

            func style2() -> UIWindow? {
                if #available(iOS 13.0, *) {
                    return keyWindowScene()?
                        .windows
                        .first(where: { $0.isKeyWindow })
                }
                return nil
            }

            func style1() -> UIWindow? {
                return UIApplication.shared.keyWindow
            }
            return style3() ?? style2() ?? style1()
        }
        
        private lazy var menuGroups: [DO.MenuGroup] = []

        private lazy var defMenuGroups: [DO.MenuGroup] = {
            
            let common = DO.MenuGroup(title: "Info", items: [
                DO.MenuItem(plugin: DO.AppInfoPlugin.shared),
                DO.MenuItem(plugin: DO.ConsolePlugin.shared),
                DO.MenuItem(plugin: DO.NetworkPlugin.shared),
                DO.MenuItem(plugin: DO.UserDefaultsPlugin.shared),
                DO.MenuItem(plugin: DO.SandboxPlugin.shared),
            ])
            
            let performance = DO.MenuGroup(title: "Performance", items: [
                DO.MenuItem(plugin: DO.PerfTrendPlugin.shared),
            ])

            let visual = DO.MenuGroup(title: "Visual", items: [
                DO.MenuItem(plugin: DO.HierarchyPlugin.shared),
            ])
            
            return [common, visual, performance]
        }()
        
    }
}
