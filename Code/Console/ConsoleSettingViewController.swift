//
//  ConsoleSettingViewController.swift
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

    /// One section per source: `NSLog` dumps a multi-line object, `print` does not, so merging is
    /// a per-stream decision rather than one for everything.
    @objc(DOConsoleSettingViewController)
    final class ConsoleSettingViewController: DO.SectionTableViewController {

        private struct Item: DO.ToggleCellDataSource {

            enum Kind {
                case enabled(DO.ConsoleLine.Source)
                case merge(DO.ConsoleLine.Source)
                case emptySubsystem
            }

            let title: String
            let detail: String
            let kind: Kind

            var isOn: Bool {
                let store = DO.ConsoleStore.shared

                switch kind {
                case .enabled(let source):
                    return store.filter.sources.contains(source)
                case .merge(let source):
                    return store.mergesSameTimestamp.contains(source)
                case .emptySubsystem:
                    return store.filter.includesEmptySubsystem
                }
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            title = DO.Text.Common.settings

            navigationItem.leftBarButtonItem = nil

            navigationController?.setToolbarHidden(true, animated: false)

            reloadSections()
        }

        private func reloadSections() {
            var sections = [DO.ConsoleLine.Source.standardOutput, .standardError].map(sourceSection)
            sections.append(unifiedLogSection())
            self.sections = sections
        }

        private func sourceSection(_ source: DO.ConsoleLine.Source) -> Section {
            return Section(
                title: source.title,
                footer: source.detail,
                rows: [
                    makeRow(Item(
                        title: DO.Text.Console.show,
                        detail: DO.Text.Console.showDetail,
                        kind: .enabled(source)
                    )),
                    makeRow(Item(
                        title: DO.Text.Console.mergeSameTimestamp,
                        detail: DO.Text.Console.mergeDetail,
                        kind: .merge(source)
                    )),
                ]
            )
        }

        private func unifiedLogSection() -> Section {
            let source = DO.ConsoleLine.Source.unifiedLog

            guard DO.ConsoleUnifiedLog.isAvailable else {
                return Section(title: source.title, footer: DO.Text.Console.unavailable, rows: [])
            }

            return Section(
                title: source.title,
                footer: source.detail + ". " + DO.Text.Console.unifiedLogFooter,
                rows: [
                    makeRow(Item(
                        title: DO.Text.Console.show,
                        detail: DO.Text.Console.showDetail,
                        kind: .enabled(source)
                    )),
                    makeRow(Item(
                        title: DO.Text.Console.mergeSameTimestamp,
                        detail: DO.Text.Console.mergeDetailUnifiedLog,
                        kind: .merge(source)
                    )),
                    makeRow(Item(
                        title: DO.Text.Console.noSubsystem,
                        detail: DO.Text.Console.noSubsystemDetail,
                        kind: .emptySubsystem
                    )),
                ]
            )
        }

        private func makeRow(_ item: Item) -> Row {
            Row(
                cellClass: DO.ToggleCell.self,
                onTrigger: { [weak self] cell in
                    self?.update(item.kind, isOn: cell.isOn)
                }
            ) { cell in
                cell.update(item)
            }
        }

        private func update(_ kind: Item.Kind, isOn: Bool) {
            let store = DO.ConsoleStore.shared

            switch kind {
            case .enabled(let source):
                if isOn {
                    store.filter.sources.insert(source)
                } else {
                    store.filter.sources.remove(source)
                }
            case .merge(let source):
                if isOn {
                    store.mergesSameTimestamp.insert(source)
                } else {
                    store.mergesSameTimestamp.remove(source)
                }
            case .emptySubsystem:
                store.filter.includesEmptySubsystem = isOn
            }
        }
    }
}
