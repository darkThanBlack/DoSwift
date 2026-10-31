//
//  ConsolePlugin.swift
//  DoSwift
//

import UIKit

///
public class ConsolePlugin: DoSwiftDefaultPlugin {
    
    public static let shared = ConsolePlugin()
    
    private init() {
        super.init(identifier: "nslog", title: "NSLog", icon: UIImage(systemName: "doc.text"))
    }
    
    private let list = ConsoleViewController()
    
    public override func show() {
        super.show()
        
        list.navigationController?.popToRootViewController(animated: false)
        list.refresh()
        
        // fd 那条链路：**幂等**，只在第一次打开时真的接管，之后一直挂着。
        // 日志是「先打几条，再打开工具看」的用法，接管一关就等于把这段时间的日志丢了。
        ConsoleStore.shared.startCollecting()
        
        // 统一日志那条：**一次查询恒定约 1 秒**（见 `ConsoleUnifiedLog` 文件头），
        // 所以只能按需查。开页面查一次，之后由页面底部那颗按钮决定。
        // 不查也不会丢内容——续读游标留着，下一次查会把这段断档全捞回来。
        ConsoleStore.shared.unifiedLog.refresh()
    }
    
    public override func makeWindow() -> OverlayWindow {
        let w = OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        w.rootViewController = UINavigationController(rootViewController: list)
        return w
    }
}
