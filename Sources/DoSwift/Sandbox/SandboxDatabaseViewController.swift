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

    /// 数据库文件 → 数据表列表
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

            /// 这是被 push 的页面：基类装的关闭按钮会顶掉返回按钮
            navigationItem.leftBarButtonItem = nil

            title = url.lastPathComponent
            loadSections()
        }

        private func loadSections() {
            guard tables.isEmpty == false else {
                sections = [Section(footer: "没有可读取的数据表。", rows: [])]
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

            sections = [Section(title: "数据表（\(tables.count)）", rows: rows)]
        }
    }

    /// 单表内容：一行一条记录，点开看整条（对应原版的「点格子看全文」）
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
                sections = [Section(footer: "没有数据。", rows: [])]
                return
            }

            let rows = result.rows.enumerated().map { index, values -> Row in
                Row(cellClass: DO.KeyValueCell.self, onTrigger: { [weak self] _ in
                    guard let self = self else { return }
                    let text = zip(result.columns, values)
                        .map { "\($0) = \($1 ?? "NULL")" }
                        .joined(separator: "\n")
                    self.navigationController?.pushViewController(
                        DO.PlainTextViewController(title: "第 \(index + 1) 行", text: text),
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
                title: "\(result.rows.count) 条记录",
                footer: result.truncated ? "只展示前 \(DO.SandboxDatabase.maxRows) 条。" : nil,
                rows: rows
            )]
        }

        /// 行标题：第一个非空值；整行都空就给行号
        private static func recordTitle(at index: Int, values: [String?]) -> String {
            if let first = values.compactMap({ $0 }).first(where: { $0.isEmpty == false }) {
                return first
            }
            return "第 \(index + 1) 行"
        }

        /// 行摘要：最多三列，超出用省略号收尾（完整内容点开看）
        private static func recordDetail(columns: [String], values: [String?]) -> String {
            let pairs = zip(columns, values).prefix(3).map { "\($0) = \($1 ?? "NULL")" }
            return pairs.joined(separator: "  ·  ") + (columns.count > 3 ? "  …" : "")
        }
    }
}
