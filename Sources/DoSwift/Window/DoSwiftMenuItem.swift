//
//  DoSwiftMenuItem.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit
/// DoSwift 菜单项，参考 MOONAssistiveTouch 的 MenuItemAction 设计
public final class DoSwiftMenuItem {

    // MARK: - Typealias

    public typealias ActionHandler = (DoSwiftMenuItem) -> Void

    // MARK: - Properties

    /// 菜单项标题
    public let title: String

    /// 菜单项图标
    public var icon: UIImage?

    /// 菜单项唯一标识
    public let identifier: String

    /// 点击事件处理
    public var actionHandler: ActionHandler?

    /// 子菜单项
    public var subMenuItems: [DoSwiftMenuItem] = []

    /// 是否启用
    public var isEnabled: Bool = true

    /// 自定义属性
    public var userInfo: [String: Any] = [:]

    // MARK: - Initializers

    public init(
        identifier: String = UUID().uuidString,
        title: String,
        icon: UIImage? = nil,
        actionHandler: ActionHandler? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.icon = icon
        self.actionHandler = actionHandler
    }

    // MARK: - Public Methods

    /// 执行菜单项动作
    public func performAction() {
        guard isEnabled else { return }
        actionHandler?(self)
    }

    /// 添加子菜单项
    public func addSubMenuItem(_ menuItem: DoSwiftMenuItem) {
        subMenuItems.append(menuItem)
    }

    /// 移除子菜单项
    public func removeSubMenuItem(withIdentifier identifier: String) {
        subMenuItems.removeAll { $0.identifier == identifier }
    }

    /// 是否有子菜单
    public var hasSubMenu: Bool {
        return !subMenuItems.isEmpty
    }
}

// MARK: - Factory Methods

extension DoSwiftMenuItem {

    /// 创建分隔符菜单项
    public static func separator() -> DoSwiftMenuItem {
        let item = DoSwiftMenuItem(
            identifier: "separator_\(UUID().uuidString)",
            title: ""
        )
        item.isEnabled = false
        return item
    }

    /// 创建返回菜单项
    public static func backItem(actionHandler: @escaping ActionHandler) -> DoSwiftMenuItem {
        return DoSwiftMenuItem(
            identifier: "back",
            title: "返回",
            icon: UIImage(systemName: "arrow.left"),
            actionHandler: actionHandler
        )
    }

    /// 创建关闭菜单项
    public static func closeItem(actionHandler: @escaping ActionHandler) -> DoSwiftMenuItem {
        return DoSwiftMenuItem(
            identifier: "close",
            title: "关闭",
            icon: UIImage(systemName: "xmark"),
            actionHandler: actionHandler
        )
    }
}

// MARK: - Equatable

extension DoSwiftMenuItem: Equatable {
    public static func == (lhs: DoSwiftMenuItem, rhs: DoSwiftMenuItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - CustomStringConvertible

extension DoSwiftMenuItem: CustomStringConvertible {
    public var description: String {
        return "DoSwiftMenuItem(id: \(identifier), title: \(title), subItems: \(subMenuItems.count))"
    }
}