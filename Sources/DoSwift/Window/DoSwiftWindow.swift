//
//  DoSwiftWindow.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 悬浮窗口，参考 DriftWindow 设计
public class DoSwiftWindow: UIWindow {

    // MARK: - Weaker Wrapper

    private class Weaker<T: AnyObject> {
        weak var me: T?

        init(_ me: T? = nil) {
            self.me = me
        }
    }

    // MARK: - Properties

    private var noResponses: [Weaker<UIView>] = []

    // MARK: - Public Methods

    /// 添加不响应事件的视图
    public func addNoResponseView(_ value: UIView) {
        // 清理已释放的弱引用
        noResponses.removeAll(where: { $0.me == nil })
        noResponses.append(Weaker(value))
    }

    // MARK: - Hit Test Override

    /// 重写 hitTest 实现事件穿透
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        // 如果点击在 noResponseView 区域，返回 nil 实现穿透
        if noResponses.filter({ $0.me != nil }).contains(where: { $0.me == view }) {
            return nil
        }

        return view
    }
}