//
//  HierarchySettingViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/10
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    @objc(DOHierarchySettingViewController)
    class HierarchySettingViewController: DO.SectionTableViewController {

        var onChange: (() -> Void)?

        private struct Item: DO.ToggleCellDataSource {

            enum Kind {
                case toggle(WritableKeyPath<DO.HierarchyConfig, Bool>)
                case selector(WritableKeyPath<DO.HierarchyConfig, DO.HierarchyConfig.Visibility>)
            }

            let title: String
            let detail: String
            let kind: Kind

            var isOn: Bool {
                guard case .toggle(let keyPath) = kind else { return false }
                return DO.HierarchyPlugin.shared.config[keyPath: keyPath]
            }
        }

        private let groups: [(title: String, items: [Item])] = [
            (DO.Text.Hierarchy.colorPickerGroup, [
                Item(title: DO.Text.Hierarchy.enabled,
                     detail: DO.Text.Hierarchy.colorPickerDetail,
                     kind: .toggle(\.isColorPickEnabled)),
                Item(title: DO.Text.Hierarchy.loupe,
                     detail: DO.Text.Hierarchy.loupeDetail,
                     kind: .selector(\.loupeVisibility)),
            ]),
            (DO.Text.Hierarchy.alignRulerGroup, [
                Item(title: DO.Text.Hierarchy.enabled,
                     detail: DO.Text.Hierarchy.alignRulerDetail,
                     kind: .toggle(\.isAlignRulerEnabled)),
                Item(title: DO.Text.Hierarchy.crossLines,
                     detail: DO.Text.Hierarchy.crossLinesDetail,
                     kind: .selector(\.rulerVisibility)),
            ]),
            (DO.Text.Hierarchy.viewHierarchyGroup, [
                Item(title: DO.Text.Hierarchy.ignorePrivateClasses,
                     detail: DO.Text.Hierarchy.ignorePrivateDetail,
                     kind: .toggle(\.isIgnorePrivateClass)),
            ]),
        ]

        override func viewDidLoad() {
            super.viewDidLoad()

            title = DO.Text.Common.settings
            reloadSections()
        }

        private func reloadSections() {
            sections = groups.enumerated().map { index, group in
                Section(
                    title: group.title,
                    footer: index == groups.count - 1
                        ? DO.Text.Hierarchy.settingsFooter
                        : nil,
                    rows: group.items.map(makeRow)
                )
            }
        }

        private func makeRow(_ item: Item) -> Row {
            switch item.kind {
            case .toggle(let keyPath):
                return Row(
                    cellClass: DO.ToggleCell.self,
                    onTrigger: { [weak self] cell in
                        self?.update { $0[keyPath: keyPath] = cell.isOn }
                    }
                ) { cell in
                    cell.update(item)
                }

            case .selector(let keyPath):
                return Row(
                    cellClass: DO.SelectorCell.self,
                    onTrigger: { [weak self] _ in self?.pick(item, keyPath: keyPath) }
                ) { cell in
                    cell.update(
                        title: item.title,
                        detail: item.detail,
                        value: DO.HierarchyPlugin.shared.config[keyPath: keyPath].title
                    )
                }
            }
        }

        private func update(_ mutate: (inout DO.HierarchyConfig) -> Void) {
            var config = DO.HierarchyPlugin.shared.config
            mutate(&config)

            DO.HierarchyPlugin.shared.config = config
            DO.HierarchyPlugin.shared.config.save()

            reloadSections()
            onChange?()
        }

        private func pick(_ item: Item, keyPath: WritableKeyPath<DO.HierarchyConfig, DO.HierarchyConfig.Visibility>) {
            let options = DO.HierarchyConfig.Visibility.allCases

            DO.HierarchyActionSheet.present(
                from: self,
                title: item.title,
                actions: options.map { $0.title }
            ) { [weak self] index in
                guard let self = self, options.indices.contains(index) else { return }
                self.update { $0[keyPath: keyPath] = options[index] }
            }
        }
    }
}
