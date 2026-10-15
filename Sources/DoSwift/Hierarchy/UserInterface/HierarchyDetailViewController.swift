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
            Section(title: model.title, rows: model.items.map { row(for: $0) })
        }
    }

    // MARK: - Rows

    /// 一行用哪种 cell，由引擎给的可编辑信息定：
    ///
    ///   只读          → `KeyValueCell`
    ///   可切换        → `ToggleCell`（开关拨动即写）
    ///   点开编辑器    → `SelectorCell`（弹出编辑卡片）
    ///
    /// 三种 cell、每行的动作、事件回流这一整套在 `SectionTableViewController` 里已经就位，
    /// 这里只是选一下。
    private func row(for item: HierarchyCellModel) -> Row {
        guard let edit = item.edit else {
            // `HierarchyCellModel` 本身就是一行的数据（实现了 `KeyValueCellDataSource`），
            // 不必再套一层适配对象
            return Row(cellClass: KeyValueCell.self) { cell in
                cell.update(item)
                // 分隔线的显隐是**按行**定的（组与组之间才留线）
                cell.separatorInset = item.separatorInsets
            }
        }

        switch edit.kind {
        case .bool(let isOn):
            return Row(
                cellClass: ToggleCell.self,
                onTrigger: { [weak self] cell in self?.writeToggle(edit, isOn: cell.isOn) }
            ) { cell in
                // 开关自带状态，副标题仍旧显示字面值，两处对得上就说明写成功了
                cell.update(title: item.title, detail: item.detailTitle, isOn: isOn)
                cell.separatorInset = item.separatorInsets
            }

        default:    // text / int / double / enum / color / font / date / 几何 —— 都要点开卡片
            return Row(
                cellClass: SelectorCell.self,
                onTrigger: { [weak self] _ in self?.presentEditor(edit) }
            ) { cell in
                cell.update(title: item.title, detail: item.detailTitle)
                cell.separatorInset = item.separatorInsets
            }
        }
    }

    // MARK: - Editing

    /// 开关拨动：直接写，不弹窗。
    ///
    /// 写完**一律重读**这张表。重读就是校验：写没写进去、被布局弹没弹回，
    /// 那一行自己会显示真实值 —— 比在引擎里回读再对一遍更准。不重读的话，
    /// 开关会停在用户拨到的位置，而属性其实没变，那是假象。
    private func writeToggle(_ edit: HierarchyEditDescriptor, isOn: Bool) {
        guard let view = selectView else { return }
        HierarchyPropertyEngine.shared.write(.bool(isOn), forKey: edit.key, to: view)
        loadData()
    }

    /// 点开编辑器。
    ///
    /// 外壳、进场、键盘、取消/完成那一整套都在 `HierarchyEditorCard` 里，和类型无关；
    /// 这里只做两件事：**按 `kind` 造一块输入区**，以及**写完之后刷新列表**。
    ///
    /// 之前那个 `switch edit.kind`（text 走 alert、enum 走 action sheet、其余默认什么都不做）
    /// 就是卡片要替掉的东西 —— 十种类型能编辑，它只认两种。
    private func presentEditor(_ edit: HierarchyEditDescriptor) {
        guard let view = selectView,
              let input = HierarchyValueInputFactory.make(for: edit.kind) else { return }

        let card = HierarchyEditorCard(key: edit.key, kind: edit.kind, input: input) { [weak self] value in
            HierarchyPropertyEngine.shared.write(value, forKey: edit.key, to: view)
            // 写完重读：那一行自己会显示真实值，这就是写入的验证
            self?.loadData()
        }
        // 转场由 `BasePresentFitViewController` + `PresentAnimation` 提供，
        // 所以这里是普通的 `animated: true`
        present(card, animated: true)
    }
}
