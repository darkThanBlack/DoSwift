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
        
        /// Your APP's scene. Overlay windows attach to it; see `DO.OverlayWindow`.
        private(set) weak var appScene: UIWindowScene?
        
        /// Pass an accurate window / scene; automated detection can never be 100% right.
        ///
        /// - Parameters:
        ///   - appWindow: the host's key window
        ///   - appScene: the host's window scene; when given, every overlay window is created in it
        public func setup(
            appScene: UIWindowScene? = nil,
            appWindow: UIWindow? = nil,
            plugins: [DO.Plugin] = []
        ) {
            self.appScene = appScene ?? appWindow?.windowScene ?? keyWindowScene()
            
            guard let w = appWindow ?? keyWindow() ?? appScene?.windows.first else {
                assertionFailure("appWindow / appScene is nil")
                return
            }
            
            self.appWindow = w
            
            self.menuGroups = defMenuGroups
            let customGroup = DO.MenuGroup(
                title: DO.Text.Common.custom,
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
            if let scene = appScene {
                return scene
            }
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
            
            let common = DO.MenuGroup(title: DO.Text.Menu.infoGroup, items: [
                DO.MenuItem(plugin: DO.AppInfoPlugin.shared),
                DO.MenuItem(plugin: DO.ConsolePlugin.shared),
                DO.MenuItem(plugin: DO.NetworkPlugin.shared),
                DO.MenuItem(plugin: DO.UserDefaultsPlugin.shared),
                DO.MenuItem(plugin: DO.SandboxPlugin.shared),
            ])
            
            let performance = DO.MenuGroup(title: DO.Text.Perf.title, items: [
                DO.MenuItem(plugin: DO.PerfTrendPlugin.shared),
            ])

            let visual = DO.MenuGroup(title: DO.Text.Menu.visualGroup, items: [
                DO.MenuItem(plugin: DO.HierarchyPlugin.shared),
            ])
            
            return [common, visual, performance]
        }()
        
    }
}
