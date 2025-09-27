//
//  DoSwiftHierarchyModels.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/27.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - View Node Model

/// 视图层级节点模型
public class DoSwiftViewNode {

    /// 关联的视图对象
    public weak var view: UIView?

    /// 节点标题 (类名)
    public let title: String

    /// 节点描述 (内存地址)
    public let subtitle: String

    /// 父节点
    public weak var parent: DoSwiftViewNode?

    /// 子节点
    public var children: [DoSwiftViewNode] = []

    /// 层级深度
    public let depth: Int

    /// 是否展开
    public var isExpanded: Bool = false

    /// 唯一标识符
    public let identifier: String

    init(view: UIView, parent: DoSwiftViewNode?, depth: Int) {
        self.view = view
        self.title = String(describing: type(of: view))
        self.subtitle = String(format: "%p", view)
        self.parent = parent
        self.depth = depth
        self.identifier = "\(title)_\(subtitle)"
    }
}

// MARK: - Property Models

/// 属性分类模型
public class DoSwiftPropertyCategory {

    /// 分类名称
    public let name: String

    /// 分类图标
    public let icon: UIImage?

    /// 属性列表
    public var properties: [DoSwiftProperty] = []

    /// 是否展开
    public var isExpanded: Bool = false

    init(name: String, icon: UIImage? = nil) {
        self.name = name
        self.icon = icon
    }
}

/// 单个属性模型
public class DoSwiftProperty {

    /// 属性名称
    public let name: String

    /// 属性值
    public var value: Any?

    /// 属性类型
    public let type: DoSwiftPropertyType

    /// KeyPath 用于动态修改
    public let keyPath: String

    /// 关联的视图对象
    public weak var targetView: UIView?

    /// 值变更回调
    public var valueChangeCallback: ((Any?) -> Void)?

    init(name: String, value: Any?, type: DoSwiftPropertyType, keyPath: String, targetView: UIView?) {
        self.name = name
        self.value = value
        self.type = type
        self.keyPath = keyPath
        self.targetView = targetView
    }
}

/// 属性类型枚举
public enum DoSwiftPropertyType {
    case string
    case number
    case bool
    case color
    case font
    case frame
    case point
    case size
    case edgeInsets
    case readonly
}

// MARK: - Hierarchy Change Notification

public extension Notification.Name {
    static let doSwiftHierarchyDidChange = Notification.Name("DoSwiftHierarchyDidChangeNotification")
}