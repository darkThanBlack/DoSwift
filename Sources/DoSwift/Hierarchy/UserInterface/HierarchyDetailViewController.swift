//
//  HierarchyDetailViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    @objc(DOHierarchyDetailViewController)
    class HierarchyDetailViewController: DO.SectionTableViewController {

        var selectView: UIView?

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "UI Structure"

            loadData()

        }

        // Property lists come from DO.HierarchyPropertyEngine (JSON-driven).
        private func loadData() {
            guard let view = selectView else { return }

            let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)

            sections = models.map { model in
                Section(title: model.title, rows: model.items.map { row(for: $0) })
            }
        }

        private func row(for item: DO.HierarchyCellModel) -> Row {
            guard let edit = item.edit else {
                return Row(cellClass: DO.KeyValueCell.self) { cell in
                    cell.update(item)
                    cell.separatorInset = item.separatorInsets
                }
            }

            switch edit.kind {
            case .bool(let isOn):
                return Row(
                    cellClass: DO.ToggleCell.self,
                    onTrigger: { [weak self] cell in self?.writeToggle(edit, isOn: cell.isOn) }
                ) { cell in
                    cell.update(title: item.title, detail: item.detailTitle, isOn: isOn)
                    cell.separatorInset = item.separatorInsets
                }

            default:
                return Row(
                    cellClass: DO.SelectorCell.self,
                    onTrigger: { [weak self] _ in self?.presentEditor(edit) }
                ) { cell in
                    cell.update(title: item.title, detail: item.detailTitle)
                    cell.separatorInset = item.separatorInsets
                }
            }
        }

        private func writeToggle(_ edit: DO.HierarchyEditDescriptor, isOn: Bool) {
            guard let view = selectView else { return }
            DO.HierarchyPropertyEngine.shared.write(.bool(isOn), forKey: edit.key, to: view)
            loadData()
        }

        private func presentEditor(_ edit: DO.HierarchyEditDescriptor) {
            guard let view = selectView,
                  let input = DO.HierarchyValueInputFactory.make(for: edit.kind) else { return }

            let card = DO.HierarchyEditorCard(key: edit.key, kind: edit.kind, input: input) { [weak self] value in
                DO.HierarchyPropertyEngine.shared.write(value, forKey: edit.key, to: view)
                self?.loadData()
            }
            present(card, animated: true)
        }
    }
}
