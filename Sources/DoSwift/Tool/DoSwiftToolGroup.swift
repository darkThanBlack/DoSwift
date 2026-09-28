//
//  DoSwiftToolGroup.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 工具分组：工具轨里的一个分节，对应 DoKit 的一个模块。
///
/// 注意这与 `DoSwiftMenuItem.subMenuItems` 的「二级菜单」是两种语义，不要混用：
/// DoKit 原版主菜单顶层就是**扁平**的 37 项，靠模块分组来组织，没有任何二级菜单。
public struct DoSwiftToolGroup {

    /// 分组标题，渲染在工具轨的分组头上（如「性能检测」）
    public let title: String

    /// 分组内的工具项，顺序即展示顺序
    public var items: [DoSwiftMenuItem]

    public init(title: String, items: [DoSwiftMenuItem]) {
        self.title = title
        self.items = items
    }
}
