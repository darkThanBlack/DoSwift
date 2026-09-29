//
//  DoSwiftMenuItem.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// 主菜单里的一个菜单项。
///
/// 刻意保持成**只有数据**：没有子菜单、没有工厂方法、不实现任何协议。
/// 主菜单是扁平的两级结构（分组 → 菜单项），行为由 `DoSwiftCore` 按 `identifier` 挂载。
public final class DoSwiftMenuItem {

    /// 菜单项唯一标识。`DoSwiftCore` 用它把行为挂上来，因此**必填**，
    /// 不能再用随机 UUID 兜底——那样会得到一个无法寻址的项。
    public let identifier: String

    /// 菜单项标题
    public let title: String

    /// 菜单项图标
    public var icon: UIImage?

    /// 点击事件处理
    public var actionHandler: ((DoSwiftMenuItem) -> Void)?

    public init(
        identifier: String,
        title: String,
        icon: UIImage? = nil,
        actionHandler: ((DoSwiftMenuItem) -> Void)? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.icon = icon
        self.actionHandler = actionHandler
    }

    /// 执行菜单项动作
    public func performAction() {
        actionHandler?(self)
    }
}
