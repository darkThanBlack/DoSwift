//
//  SandboxDatabaseViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// One SQLite file: its tables.
    @objc(DOSandboxDatabaseViewController)
    final class SandboxDatabaseViewController: DO.SectionTableViewController {

        private let url: URL

        private lazy var tables: [String] = DO.SandboxDatabase.tables(at: url)

        init(url: URL) {
            self.url = url
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            /// Pushed, so the base class's close button would replace the back button.
            navigationItem.leftBarButtonItem = nil

            title = url.lastPathComponent
            loadSections()
        }

        private func loadSections() {
            guard tables.isEmpty == false else {
                sections = [Section(footer: DO.Text.Sandbox.noTables, rows: [])]
                return
            }

            let rows = tables.map { table in
                Row(cellClass: DO.SelectorCell.self, onTrigger: { [weak self] _ in
                    guard let self = self else { return }
                    self.navigationController?.pushViewController(
                        DO.SandboxDatabaseTableViewController(url: self.url, table: table),
                        animated: true
                    )
                }) { cell in
                    cell.update(title: table, detail: "")
                }
            }

            sections = [Section(title: DO.Text.Sandbox.dataTables(tables.count), rows: rows)]
        }
    }

    /// One table: a row per record, tap to see the whole thing.
    @objc(DOSandboxDatabaseTableViewController)
    final class SandboxDatabaseTableViewController: DO.SectionTableViewController {

        private let url: URL

        private let table: String

        private var result: DO.SandboxDatabase.TableRows?

        init(url: URL, table: String) {
            self.url = url
            self.table = table
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            navigationItem.leftBarButtonItem = nil

            title = table
            result = DO.SandboxDatabase.rows(at: url, table: table)
            loadSections()
        }

        private func loadSections() {
            guard let result = result, result.rows.isEmpty == false else {
                sections = [Section(footer: DO.Text.Sandbox.noRows, rows: [])]
                return
            }

            let rows = result.rows.enumerated().map { index, values -> Row in
                Row(cellClass: DO.KeyValueCell.self, onTrigger: { [weak self] _ in
                    guard let self = self else { return }
                    let text = zip(result.columns, values)
                        .map { "\($0) = \($1 ?? "NULL")" }
                        .joined(separator: "\n")
                    self.navigationController?.pushViewController(
                        DO.PlainTextViewController(title: DO.Text.Sandbox.row(index), text: text),
                        animated: true
                    )
                }) { cell in
                    cell.update(
                        title: Self.recordTitle(at: index, values: values),
                        detail: Self.recordDetail(columns: result.columns, values: values)
                    )
                    cell.detailNumberOfLines = 2
                    cell.selectionStyle = .default
                }
            }

            sections = [Section(
                title: DO.Text.Sandbox.recordCount(result.rows.count),
                footer: result.truncated ? DO.Text.Sandbox.truncated(maxRows: DO.SandboxDatabase.maxRows) : nil,
                rows: rows
            )]
        }

        /// First non-empty value, else the row number.
        private static func recordTitle(at index: Int, values: [String?]) -> String {
            if let first = values.compactMap({ $0 }).first(where: { $0.isEmpty == false }) {
                return first
            }
            return DO.Text.Sandbox.row(index)
        }

        /// At most three columns, ellipsis after that.
        private static func recordDetail(columns: [String], values: [String?]) -> String {
            let pairs = zip(columns, values).prefix(3).map { "\($0) = \($1 ?? "NULL")" }
            return pairs.joined(separator: "  ·  ") + (columns.count > 3 ? "  …" : "")
        }
    }
}
