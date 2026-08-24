//
//  DoSwiftContext.swift
//  DoSwift
//
//  Created by Claude Code on 2026/08/21.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// DoSwift 全局共享上下文。
///
/// 持有跨插件共享的全局状态——当前只有业务 app 的主 window。
/// 各插件因自身业务需要创建的遮罩 window（如 HierarchyWindow）不属于全局，
/// 由插件各自持有，不放在这里。
public final class DoSwiftContext {

    public static let shared = DoSwiftContext()

    private init() {}

    // MARK: - Properties

    /// 业务 app 的主 window。
    /// weak 持有：window 的生命周期由业务自身管理，DoSwift 不应强引用。
    public private(set) weak var appWindow: UIWindow?

    // MARK: - Public Interface

    /// 设置业务 app 的主 window。
    /// 业务侧在 AppDelegate（或 SceneDelegate）拿到真正的 window 后调用，
    /// UI 结构等跨插件能力据此定位业务视图。
    public func setup(_ window: UIWindow?) {
        self.appWindow = window
    }
}
