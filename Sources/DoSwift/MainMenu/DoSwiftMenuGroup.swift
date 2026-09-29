//
//  DoSwiftMenuGroup.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 主菜单的一个分组，对应 DoKit 的一个模块。
///
/// 主菜单是扁平的两级结构：**分组 → 菜单项**，没有二级菜单。
public struct DoSwiftMenuGroup {

    /// 分组标题，渲染在面板的分组头上（如「性能检测」）
    public let title: String

    /// 分组内的菜单项，顺序即展示顺序
    public var items: [DoSwiftMenuItem]

    public init(title: String, items: [DoSwiftMenuItem]) {
        self.title = title
        self.items = items
    }
}
