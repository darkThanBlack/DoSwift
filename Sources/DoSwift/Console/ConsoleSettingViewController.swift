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

    @objc(DOConsoleSettingViewController)
    final class ConsoleSettingViewController: DO.SectionTableViewController {

        private struct Item: DO.ToggleCellDataSource {

            enum Kind {
                case source(DO.ConsoleLine.Source)
                case emptySubsystem
            }

            let title: String
            let detail: String
            let kind: Kind

            var isOn: Bool {
                switch kind {
                case .source(let source):
                    return DO.ConsoleStore.shared.filter.sources.contains(source)
                case .emptySubsystem:
                    return DO.ConsoleStore.shared.filter.includesEmptySubsystem
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
            let sources = DO.ConsoleLine.Source.allCases.filter {
                $0 != .unifiedLog || DO.ConsoleUnifiedLog.isAvailable
            }

            var sections: [Section] = [
                Section(
                    title: "Sources",
                    footer: "Lines are tagged with the link they came from. "
                          + "Both fd links are received by one pipe tee, and are restored when the app exits.",
                    rows: sources.map { source in
                        makeRow(Item(title: source.title, detail: source.detail, kind: .source(source)))
                    }
                )
            ]

            if DO.ConsoleUnifiedLog.isAvailable {
                sections.append(
                    Section(
                        title: "Unified Log",
                        footer: "Read back through OSLogStore, current process only, iOS 15 or later. "
                              + "One read costs about a second regardless of how much is there, "
                              + "so it runs when you open the page and whenever you tap the button — "
                              + "never on a timer. "
                              + "Interpolated values are private by default: only what was logged with "
                              + "`privacy: .public` (and numbers) can be read, everything else is <private>.",
                        rows: [
                            makeRow(Item(
                                title: "No Subsystem",
                                detail: "A bare `Logger()` has an empty subsystem — "
                                      + "could be yours, could be a framework's",
                                kind: .emptySubsystem
                            ))
                        ]
                    )
                )
            } else {
                sections.append(
                    Section(title: "Unified Log", footer: "Unavailable on this system.", rows: [])
                )
            }

            self.sections = sections
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
            switch kind {
            case .source(let source):
                if isOn {
                    DO.ConsoleStore.shared.filter.sources.insert(source)
                } else {
                    DO.ConsoleStore.shared.filter.sources.remove(source)
                }
            case .emptySubsystem:
                DO.ConsoleStore.shared.filter.includesEmptySubsystem = isOn
            }
        }
    }
}
