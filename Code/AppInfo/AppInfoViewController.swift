//
//  AppInfoViewController.swift
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

    @objc(DOAppInfoViewController)
    final class AppInfoViewController: DO.SectionTableViewController {

        var customRows: [DO.AppInfoRow] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "App 信息"
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "复制 JSON",
                style: .plain,
                target: self,
                action: #selector(copyJSON)
            )
        }

        func refresh() {
            DO.AppInfo.shared.onChange = { [weak self] in self?.reload() }

            DO.AppInfo.shared.reload()
            reload()
        }

        override func close() {
            DO.AppInfoPlugin.shared.hide()
        }

        private func reload() {
            sections = displaySections.map { section in
                Section(title: section.title, rows: section.rows.map { row in
                    Row(cellClass: DO.KeyValueCell.self, onTrigger: { _ in
                        UIPasteboard.general.string = row.value
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) { cell in
                        cell.update(title: row.title, detail: row.value)
                        cell.selectionStyle = .default
                    }
                })
            }
        }

        private var displaySections: [DO.AppInfoSection] {
            var data = DO.AppInfo.shared.sections()
            if !customRows.isEmpty {
                data.append((title: "自定义", rows: customRows))
            }
            return data
        }

        @objc private func copyJSON() {
            var json: [String: [String: String]] = [:]
            for section in displaySections {
                var rows: [String: String] = [:]
                for row in section.rows {
                    rows[row.title] = row.value
                }
                json[section.title] = rows
            }

            guard let data = try? JSONSerialization.data(
                    withJSONObject: json,
                    options: [.prettyPrinted, .sortedKeys]
                  ),
                  let text = String(data: data, encoding: .utf8)
            else { return }

            UIPasteboard.general.string = text
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
