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

        weak var selectView: UIView?

        override func viewDidLoad() {
            super.viewDidLoad()

            title = DO.Text.Hierarchy.detailTitle

            loadData()

        }

        // Property lists come from DO.HierarchyPropertyEngine (JSON-driven).
        private func loadData() {
            guard let view = selectView else { return }

            let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)

            var result: [Section] = models.map { model in
                Section(title: model.title, rows: model.items.map { row(for: $0) })
            }

            // Constraints are a runtime set, so they sit right after the first JSON group
            // instead of being declared in the JSON.
            result.insert(constraintSection(for: view), at: min(1, result.count))
            sections = result
        }

        private func constraintSection(for view: UIView) -> Section {
            let engine = DO.HierarchyConstraintEngine.shared
            let constraints = engine.constraints(involving: view)

            let rows: [Row] = constraints.map { constraint in
                let summary = engine.summary(for: constraint, from: view)
                return Row(
                    cellClass: DO.SelectorCell.self,
                    onTrigger: { [weak self, weak view] _ in
                        guard let view = view else { return }
                        self?.presentConstraintEditor(constraint, view: view)
                    }
                ) { cell in
                    cell.titleNumberOfLines = 0
                    cell.update(title: summary.fullText, detail: nil)
                }
            }

            return Section(
                title: DO.Text.Hierarchy.constraintSection(constraints.count),
                footer: constraints.isEmpty ? DO.Text.Hierarchy.constraintEmpty : nil,
                rows: rows
            )
        }

        private func presentConstraintEditor(_ constraint: NSLayoutConstraint, view: UIView) {
            let summary = DO.HierarchyConstraintEngine.shared.summary(for: constraint, from: view)
            let card = DO.HierarchyConstraintEditorCard(
                constraint: constraint,
                summary: summary,
                targetView: view
            ) { [weak self] in
                self?.loadData()
            }
            present(card, animated: true)
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

            let card = DO.HierarchyEditorCard(key: edit.key, kind: edit.kind, input: input) { [weak self, weak view] value in
                guard let view = view else { return }
                DO.HierarchyPropertyEngine.shared.write(value, forKey: edit.key, to: view)
                self?.loadData()
            }
            present(card, animated: true)
        }
    }
}
