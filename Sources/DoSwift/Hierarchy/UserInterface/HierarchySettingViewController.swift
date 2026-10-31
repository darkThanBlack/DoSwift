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

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "Settings"
            reloadSections()
        }

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
                        detail: DO.HierarchyPlugin.shared.config[keyPath: keyPath].title
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
            let current = DO.HierarchyPlugin.shared.config[keyPath: keyPath]

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
}
