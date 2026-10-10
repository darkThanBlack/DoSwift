//
//  HierarchyConfig.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/10.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构工具的全部配置：**唯一一份状态**，由 `HierarchyPlugin` 持有。
///
/// - **读**：单例初始化时 `HierarchyConfig.load()` 走一次本地反序列化，之后运行时读的
///   都是内存属性，不再碰 `UserDefaults`。
/// - **写**：配置页每次改动后 `save()` 把整个对象写回去。
///
/// 于是「key 叫什么、怎么序列化」只有这一个文件知道，也不会出现
/// 「界面显示开、工具按关执行」这种两份状态打架的局面。
struct HierarchyConfig: Codable, Equatable {

    /// 显隐三态。刻意做成三态而不是「开/关」：标线和放大镜在「只在拖动时出现」这一档
    /// 才最有用，而「一直挂着看不看」和「从来不想要」也都是真实需求。
    enum Visibility: String, Codable, CaseIterable {

        case never
        case whileDragging
        case always

        var title: String {
            switch self {
            case .never:         return "Never"
            case .whileDragging: return "While Dragging"
            case .always:        return "Always"
            }
        }

        /// 在当前的「是否正在拖动」下该不该显示
        func isVisible(whileDragging isDragging: Bool) -> Bool {
            switch self {
            case .never:         return false
            case .whileDragging: return isDragging
            case .always:        return true
            }
        }
    }

    // MARK: - 取色器

    /// 总开关：Pixel 行 + 放大镜
    var isColorPickEnabled: Bool = true

    /// 放大镜自己的显隐。**关掉总开关时此项无意义**——总开关管「这个功能要不要」，
    /// 这里管「它的浮层什么时候出现」，所以 `never` 与 `isColorPickEnabled = false`
    /// 并不重复：前者留下 Pixel 读数，只是不要放大镜。
    var loupeVisibility: Visibility = .whileDragging

    // MARK: - 标尺

    /// 总开关：Position 行 + 标线
    var isAlignRulerEnabled: Bool = true

    /// 标线自己的显隐。同上：`never` 时四个距离照旧显示，只是不画线。
    var rulerVisibility: Visibility = .always

    // MARK: - 视图结构

    /// 类名以下划线开头的 view 不参与拾取，也不出现在 Parent / Childs 列表里
    var isIgnorePrivateClass: Bool = true

    // MARK: - 存取

    /// key 前缀 `k...` 与 `DoSwiftMenuHandle.handleFrameKey` 一致
    private static let defaultsKey = "kHierarchyConfig"

    static func load() -> HierarchyConfig {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let config = try? JSONDecoder().decode(HierarchyConfig.self, from: data) else {
            return HierarchyConfig()
        }
        return config
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case isColorPickEnabled, loupeVisibility
        case isAlignRulerEnabled, rulerVisibility
        case isIgnorePrivateClass
    }

    /// 手写 `init(from:)` 而不用合成的：合成版遇到**缺字段**直接抛错，于是老配置在
    /// 新增一个开关之后整份作废、静默回到默认值。这里逐字段 `decodeIfPresent` 兜默认值,
    /// 以后加开关不会掀桌子。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = HierarchyConfig()

        isColorPickEnabled = try container.decodeIfPresent(Bool.self, forKey: .isColorPickEnabled)
            ?? fallback.isColorPickEnabled
        loupeVisibility = try container.decodeIfPresent(Visibility.self, forKey: .loupeVisibility)
            ?? fallback.loupeVisibility
        isAlignRulerEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAlignRulerEnabled)
            ?? fallback.isAlignRulerEnabled
        rulerVisibility = try container.decodeIfPresent(Visibility.self, forKey: .rulerVisibility)
            ?? fallback.rulerVisibility
        isIgnorePrivateClass = try container.decodeIfPresent(Bool.self, forKey: .isIgnorePrivateClass)
            ?? fallback.isIgnorePrivateClass
    }

    /// 全默认值。写了 `init(from:)` 之后编译器就不再合成逐成员构造器，得自己给一个。
    init() {}
}
