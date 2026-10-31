//
//  DoSwiftCore.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

public class DoSwiftCore {
    
    public static let shared = DoSwiftCore()
    private init() {}
    
    /// Your APP's window
    public private(set) weak var appWindow: UIWindow?
    
    /// DoSwift main menu drift handle
    public private(set) var window: OverlayWindow?
    
    ///
    public func start(
        appWindow: UIWindow?,
        plugins: [DoSwiftPlugin] = []
    ) {
        self.appWindow = appWindow
        
        self.menuGroups = defMenuGroups
        let customGroup = DoSwiftMenuGroup(
            title: "自定义",
            items: plugins.map({ DoSwiftMenuItem(plugin: $0) })
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
    
    // MARK: - Private
    
    private lazy var menuGroups: [DoSwiftMenuGroup] = []
    
    private lazy var defMenuGroups: [DoSwiftMenuGroup] = {
        
        func item(_ id: String, _ title: String, _ symbol: String) -> DoSwiftMenuItem {
            return DoSwiftMenuItem(identifier: id, title: title, icon: UIImage(systemName: symbol))
        }
        
        let common = DoSwiftMenuGroup(title: "常用工具", items: [
            item("app_setting",    "应用设置",      "gear"),
            DoSwiftMenuItem(plugin: AppInfoPlugin.shared),
            item("sandbox",        "沙盒浏览器",    "folder"),
            item("mock_gps",       "Mock GPS",      "location"),
            item("h5",             "H5任意门",      "safari"),
            item("clean_cache",    "清理缓存",      "trash"),
            DoSwiftMenuItem(plugin: ConsolePlugin.shared),
            item("db_view",        "DBView",        "archivebox"),
            DoSwiftMenuItem(plugin: UserDefaultsPlugin.shared),
            item("js_script",      "JS脚本",        "chevron.left.slash.chevron.right"),
        ])
        
        let performance = DoSwiftMenuGroup(title: "性能", items: [
            DoSwiftMenuItem(plugin: PerfTrendPlugin.shared),
        ])
        
        let visual = DoSwiftMenuGroup(title: "视觉工具", items: [
            DoSwiftMenuItem(plugin: HierarchyPlugin.shared),
        ])
        
        return [visual, performance, common]
    }()
    
    private func prepare() {
        guard window == nil else { return }
        
        let overlayWindow = OverlayWindow(frame: UIScreen.main.bounds, level: .statusBar)
        overlayWindow.isHidden = true
        overlayWindow.backgroundColor = .clear
        
        let root = DoSwiftMainViewController()
        root.menuGroups = menuGroups
        overlayWindow.rootViewController = root
        
        window = overlayWindow
        
        overlayWindow.addNoResponseView(root.view)
    }
    
}
