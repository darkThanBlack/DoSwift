//
//  UserDefaultsPlugin.swift
//  DoSwift
//

import UIKit

///
public class UserDefaultsPlugin: DoSwiftDefaultPlugin {
    
    public static let shared = UserDefaultsPlugin()
    
    private init() {
        super.init(identifier: "user_defaults", title: "UserDefaults", icon: UIImage(systemName: "rectangle.grid.2x2"))
    }
    
    private let list = UserDefaultsViewController()
    
    /// 显示浏览器
    ///
    /// 窗口是复用的，上一次退出时的局面（停在详情页、还在编辑态、搜索框里还有字）
    /// 不该带到这一次来：先回根页，再重读一次数据。
    public override func show() {
        super.show()

        list.navigationController?.popToRootViewController(animated: false)
        list.refresh()
    }
    
    public override func makeWindow() -> OverlayWindow {
        let w = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        w.rootViewController = UINavigationController(rootViewController: list)
        return w
    }
}
