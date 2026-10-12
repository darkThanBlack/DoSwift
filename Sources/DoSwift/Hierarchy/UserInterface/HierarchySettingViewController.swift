//
//  HierarchySettingViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/10.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构工具的配置页。
///
/// 只做一件事：**把每个开关的写操作导向 `HierarchyPlugin.config`**。值怎么存、存哪
/// 由 `HierarchyConfig` 负责，页面自己不缓存任何状态——于是不可能出现
/// 「界面显示开、工具按关执行」这种两份状态打架的情况。
///
/// 表的骨架来自 `SectionTableViewController`，本页只负责「哪一段有哪几行」
/// 和「改哪一项」——事件在哪一行上就地写掉，本页连 `UITableView` 的协议都不实现。
/// 每次改动都即时落盘（`persistConfig()`）并回调 `onChange`，
/// 所以没有「保存」按钮，也不会出现改完忘了确认就退出。
class HierarchySettingViewController: SectionTableViewController {

    /// 任一项变化后回调，让主界面立刻反映（关掉标线就收线、关掉取色就收放大镜）
    var onChange: (() -> Void)?

    // MARK: - Model

    /// 一个配置项。
    ///
    /// 顺带实现 `ToggleCellDataSource`：开关行要的三样正好都在它身上，
    /// 于是 cell 直接吃这一项（`cell.update(item)`），不必再造适配对象。
    ///
    /// 选择行不适合这么做——它的副标题要放**当前取值**，而这里的 `detail` 是那段说明，
    /// 所以那一行的副标题走传参入口。
    private struct Item: ToggleCellDataSource {

        enum Kind {
            case toggle(WritableKeyPath<HierarchyConfig, Bool>)
            case selector(WritableKeyPath<HierarchyConfig, HierarchyConfig.Visibility>)
        }

        let title: String
        let detail: String
        let kind: Kind

        var isOn: Bool {
            guard case .toggle(let keyPath) = kind else { return false }
            return HierarchyPlugin.shared.config[keyPath: keyPath]
        }
    }

    /// 三个分组固定：取色器 / 标尺 / 视图结构。
    ///
    /// 每一组都是「功能总开关」+「它的浮层什么时候出现」两行——总开关管「要不要」，
    /// 显隐管「什么时候看得见」，两者不重复。
    private let groups: [(title: String, items: [Item])] = [
        ("Color Picker", [
            Item(title: "Enabled",
                 detail: "Pixel color readout in the panel, plus the loupe",
                 kind: .toggle(\.isColorPickEnabled)),
            Item(title: "Loupe",
                 detail: "When the magnifier appears",
                 kind: .selector(\.loupeVisibility)),
        ]),
        ("Align Ruler", [
            Item(title: "Enabled",
                 detail: "Distances to the four edges in the panel, plus the cross lines",
                 kind: .toggle(\.isAlignRulerEnabled)),
            Item(title: "Cross Lines",
                 detail: "When the ruler lines appear",
                 kind: .selector(\.rulerVisibility)),
        ]),
        ("View Hierarchy", [
            Item(title: "Ignore Private Classes",
                 detail: "Skip views whose class name starts with an underscore",
                 kind: .toggle(\.isIgnorePrivateClass)),
        ]),
    ]

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        reloadSections()
    }

    // MARK: - Content

    /// 由 `groups` + 当前配置算出表的内容。
    ///
    /// 每次改完都重算：页面不缓存状态，配置是唯一事实来源，
    /// 于是「开关显示的位置」和「工具实际读到的位置」不可能是两个。
    private func reloadSections() {
        sections = groups.enumerated().map { index, group in
            Section(
                title: group.title,
                footer: index == groups.count - 1
                    ? "Applied immediately and remembered in UserDefaults."
                    : nil,
                rows: group.items.map(makeRow)
            )
        }
    }

    /// 一个配置项 → 一行。
    ///
    /// 事件写在这里而不是 `didSelectRowAt` / 代理方法里：**一行自己知道自己是谁**，
    /// 于是闭包直接捕获 `item`，谁都不必靠 `indexPath` 反查回配置项。
    private func makeRow(_ item: Item) -> Row {
        switch item.kind {
        case .toggle(let keyPath):
            return Row(
                cellClass: ToggleCell.self,
                onTrigger: { [weak self] cell in
                    // 事件不带值，值此刻就在 cell 上
                    self?.update { $0[keyPath: keyPath] = cell.isOn }
                }
            ) { cell in
                cell.update(item)
            }

        case .selector(let keyPath):
            return Row(
                cellClass: SelectorCell.self,
                onTrigger: { [weak self] _ in self?.pick(item, keyPath: keyPath) }
            ) { cell in
                // 副标题放「当前值」：一眼看到状态，比再写一遍说明有用
                cell.update(
                    title: item.title,
                    detail: HierarchyPlugin.shared.config[keyPath: keyPath].title
                )
            }
        }
    }

    // MARK: - Write

    /// 改配置的唯一出口：改 → 落盘 → 刷表 → 通知主界面。
    ///
    /// 四步绑在一起，就不存在「改了没存」或「存了没刷新」这种漏一步的写法。
    private func update(_ mutate: (inout HierarchyConfig) -> Void) {
        var config = HierarchyPlugin.shared.config
        mutate(&config)

        HierarchyPlugin.shared.config = config
        HierarchyPlugin.shared.persistConfig()

        reloadSections()
        onChange?()
    }

    // MARK: - Actions

    /// 弹出选择器改「浮层什么时候出现」
    private func pick(_ item: Item, keyPath: WritableKeyPath<HierarchyConfig, HierarchyConfig.Visibility>) {
        let options = HierarchyConfig.Visibility.allCases
        let current = HierarchyPlugin.shared.config[keyPath: keyPath]

        hierarchy_showActionSheet(
            title: item.title,
            actions: options.map { $0.title },
            currentAction: current.title
        ) { [weak self] index in
            guard let self = self, options.indices.contains(index) else { return }
            self.update { $0[keyPath: keyPath] = options[index] }
        }
    }
}
