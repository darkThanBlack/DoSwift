//
//  AppInfoPlugin.swift
//  DoSwift
//

import UIKit

///
public class AppInfoPlugin: DO.DefaultPlugin {
    
    public static let shared = AppInfoPlugin()
    
    private init() {
        super.init(identifier: "app_info", title: "App信息", icon: UIImage(systemName: "info.circle"))
    }
    
    /// 显示面板。
    ///
    /// 窗口是复用的，上一次退出时的局面（停在全文页、看到的是旧值）不该带到这一次来：
    /// 先回根页，再重取一次数据。
    public override func show() {
        super.show()

        list.navigationController?.popToRootViewController(animated: false)
        list.refresh()
    }

    public override func makeWindow() -> DO.OverlayWindow {
        let w = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        w.rootViewController = UINavigationController(rootViewController: list)
        return w
    }
    
    private let list = AppInfoViewController()
    
    public func setCustomItems(_ rows: [DoSwiftAppInfoRow]) {
        list.customRows = rows
    }
}
