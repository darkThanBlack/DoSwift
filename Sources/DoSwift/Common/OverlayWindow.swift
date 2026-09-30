//
//  OverlayWindow.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 的附加 window，主菜单与各工具共用。
///
/// - **事件透传**：登记进来的视图被命中时 `hitTest` 返回 nil，触摸继续交给下层
///    window。主菜单的「非模态」就是靠这个实现的——面板之外的区域照常能操作业务 App。
///
/// 刻意不做的事：不设 `rootViewController`（由调用方给）、不设窗口层级
/// （`level` 是构造参数，不是开关）。
public class OverlayWindow: UIWindow {
    
    private class Weaker<T: AnyObject> {
        weak var me: T?
        
        init(_ me: T? = nil) {
            self.me = me
        }
    }
    
    // MARK: - Properties
    
    private var noResponses: [Weaker<UIView>] = []
    
    public init(frame: CGRect, level: UIWindow.Level = .normal) {
        super.init(frame: frame)
        windowLevel = level
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        isHidden = false
    }
    
    public func hide() {
        isHidden = true
    }
    
    /// 登记一个「不响应事件」的视图：命中它时本窗口返回 nil，触摸穿透到下层 window。
    public func addNoResponseView(_ value: UIView) {
        // 清理已释放的弱引用
        noResponses.removeAll(where: { $0.me == nil })
        noResponses.append(Weaker(value))
    }
    
    /// 取消登记
    public func removeNoResponseView(_ value: UIView) {
        noResponses.removeAll(where: { $0.me == nil || $0.me === value })
    }
    
    // MARK: - Hit Test
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        // 命中已登记的视图 → 返回 nil，让事件继续往下层 window 走
        if let hit = view, noResponses.contains(where: { $0.me === hit }) {
            return nil
        }
        
        return view
    }
    
}
