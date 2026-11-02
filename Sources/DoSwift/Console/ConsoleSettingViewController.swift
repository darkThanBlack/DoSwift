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

    /// One section per source, each carrying its own show / merge switches.
    ///
    /// Grouping by source instead of by switch kind matters here: the two fd streams behave
    /// differently in practice (`NSLog` dumps multi-line objects, `print` does not), so the
    /// merge decision has to be made per stream rather than once for everything.
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

            title = "Settings"

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
                        title: "Show",
                        detail: "Include these lines in the list.",
                        kind: .enabled(source)
                    )),
                    makeRow(Item(
                        title: "Merge same timestamp",
                        detail: "Consecutive lines sharing a timestamp become one block. "
                              + "Applies to lines that arrive from now on.",
                        kind: .merge(source)
                    )),
                ]
            )
        }

        private func unifiedLogSection() -> Section {
            let source = DO.ConsoleLine.Source.unifiedLog

            guard DO.ConsoleUnifiedLog.isAvailable else {
                return Section(title: source.title, footer: "Unavailable on this system.", rows: [])
            }

            return Section(
                title: source.title,
                footer: source.detail + ". "
                      + "One read costs about a second regardless of how much is there, so it runs "
                      + "when you open the page or tap the button — never on a timer. Interpolated "
                      + "values are private by default: only what was logged with `privacy: .public` "
                      + "(and numbers) can be read.",
                rows: [
                    makeRow(Item(
                        title: "Show",
                        detail: "Include these lines in the list.",
                        kind: .enabled(source)
                    )),
                    makeRow(Item(
                        title: "Merge same timestamp",
                        detail: "Off by default — unified log entries already carry their own boundaries.",
                        kind: .merge(source)
                    )),
                    makeRow(Item(
                        title: "No Subsystem",
                        detail: "A bare `Logger()` has an empty subsystem — could be yours, could be a framework's",
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
