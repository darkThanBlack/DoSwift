//
//  HierarchyDetailViewController.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyDetailViewController.m / .h
//

import UIKit

/// 一个 view 的属性面板。表的骨架来自 `SectionTableViewController`，
/// 本页只负责**内容**：把引擎给的模型翻成段和行。
class HierarchyDetailViewController: SectionTableViewController {

    var selectView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UI Structure"

        loadData()

        // 原版这里监听 `DoraemonHierarchyChangeNotification` 来刷新属性值，
        // 但本仓库没有任何地方 post 它（改属性的回填功能还没做），所以整套监听已删。
        // 回填做起来时再一起加。
    }

    // MARK: - Data

    // Property lists come from HierarchyPropertyEngine (JSON-driven).
    private func loadData() {
        guard let view = selectView else { return }

        // 置顶段在前、类段在后，**不再分页**：读一个 view 的顺序本来就是
        // 「多大、在哪」→「是什么」，切成两页只会让人来回切。
        // 段标题不由这里决定：置顶段取 JSON 的键名，类段由引擎从类名派生。
        let models = HierarchyPropertyEngine.shared.categoryModels(for: view)

        sections = models.map { model in
            Section(title: model.title, rows: model.items.map { item in
                // `HierarchyCellModel` 本身就是一行的数据（实现了 `KeyValueCellDataSource`），
                // 不必再套一层适配对象
                Row(cellClass: KeyValueCell.self) { cell in
                    cell.update(item)
                    // 分隔线的显隐是**按行**定的（组与组之间才留线）
                    cell.separatorInset = item.separatorInsets
                }
            })
        }
    }

}
