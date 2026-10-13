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
    ///   点开编辑器    → `SelectorCell`（textarea / action sheet）
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

        switch edit.editor {
        case "bool":
            return Row(
                cellClass: ToggleCell.self,
                onTrigger: { [weak self] cell in self?.writeToggle(edit, isOn: cell.isOn) }
            ) { cell in
                // 开关自带状态，副标题仍旧显示字面值，两处对得上就说明写成功了
                cell.update(title: item.title,
                            detail: item.detailTitle,
                            isOn: edit.currentValue as? Bool ?? false)
                cell.separatorInset = item.separatorInsets
            }

        default:    // text / enum —— 都要点开一个编辑器
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
    /// 写失败（没有 setter / 被布局改回）时重载这一行——把开关拨回**真实状态**。
    /// 不重载的话开关会停在用户拨到的位置，而属性其实没变，那是假象。
    private func writeToggle(_ edit: HierarchyEditDescriptor, isOn: Bool) {
        guard let view = selectView else { return }
        if !HierarchyPropertyEngine.shared.write(NSNumber(value: isOn), forKey: edit.key, to: view) {
            loadData()
        }
    }

    /// 点开编辑器：text 走输入框，enum 走 action sheet（带当前项勾选）。
    private func presentEditor(_ edit: HierarchyEditDescriptor) {
        guard let view = selectView else { return }

        switch edit.editor {
        case "text":
            hierarchy_showTextFieldAlert(message: edit.key, text: edit.currentValue as? String) { [weak self] text in
                guard let self = self, let text = text else { return }
                if HierarchyPropertyEngine.shared.write(text, forKey: edit.key, to: view) {
                    self.loadData()
                }
            }

        case "enum":
            let enumType = edit.enumType ?? ""
            let options = HierarchyPropertyEngine.shared.enumOptions(
                for: enumType,
                currentRawValue: edit.currentValue as? Int ?? 0
            )
            guard !options.names.isEmpty else { return }

            hierarchy_showActionSheet(
                title: edit.key,
                actions: options.names,
                currentAction: options.currentIndex.map { options.names[$0] }
            ) { [weak self] index in
                guard let self = self,
                      let rawValue = HierarchyPropertyEngine.shared.enumValue(for: enumType, at: index),
                      HierarchyPropertyEngine.shared.write(NSNumber(value: rawValue), forKey: edit.key, to: view)
                else { return }
                self.loadData()
            }

        default:
            break
        }
    }

}
