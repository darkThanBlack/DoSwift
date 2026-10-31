//
//  SectionTableViewController.swift
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

    class SectionTableViewController: UIViewController, DO.SectionCellDelegate {

        struct Row {

            let cellClass: UITableViewCell.Type

            private let configureBox: (UITableViewCell) -> Void
            private let triggerBox: (UITableViewCell) -> Void

            init<C: UITableViewCell>(
                cellClass: C.Type,
                onTrigger: ((C) -> Void)? = nil,
                configure: @escaping (C) -> Void
            ) {
                self.cellClass = cellClass
                self.configureBox = { cell in
                    guard let cell = cell as? C else { return }
                    configure(cell)
                }
                self.triggerBox = { cell in
                    guard let cell = cell as? C else { return }
                    onTrigger?(cell)
                }
            }

            func configure(_ cell: UITableViewCell) {
                configureBox(cell)
            }

            func trigger(_ cell: UITableViewCell) {
                triggerBox(cell)
            }
        }

        struct Section {

            var title: String?
            var footer: String?
            var rows: [Row]

            init(title: String? = nil, footer: String? = nil, rows: [Row]) {
                self.title = title
                self.footer = footer
                self.rows = rows
            }
        }

        var sections: [Section] = [] {
            didSet {
                registerCellClasses()
                tableView.reloadData()
            }
        }

        private var registeredIdentifiers: Set<String> = []

        lazy var tableView: UITableView = {
            let tableView = UITableView(frame: .zero, style: .insetGrouped)
            tableView.dataSource = self
            tableView.delegate = self

            tableView.bounces = false

            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 56

            tableView.register(
                DO.SectionHeaderView.self,
                forHeaderFooterViewReuseIdentifier: String(describing: DO.SectionHeaderView.self)
            )
            tableView.register(
                DO.SectionFooterView.self,
                forHeaderFooterViewReuseIdentifier: String(describing: DO.SectionFooterView.self)
            )

            tableView.separatorStyle = .none
            return tableView
        }()

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .systemGroupedBackground
            view.addSubview(tableView)

            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(close)
            )

            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        @objc func close() {
            dismiss(animated: true)
        }

        private func registerCellClasses() {
            for row in sections.flatMap(\.rows) {
                let identifier = String(describing: row.cellClass)
                guard registeredIdentifiers.insert(identifier).inserted else { continue }
                tableView.register(row.cellClass, forCellReuseIdentifier: identifier)
            }
        }

        func sectionCellDidTrigger(_ cell: UITableViewCell) {
            guard let indexPath = tableView.indexPath(for: cell) else { return }

            if !tableView.isEditing {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let indexPath = self.tableView.indexPath(for: cell) else { return }
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }

            sections[indexPath.section].rows[indexPath.row].trigger(cell)
        }
    }

}

extension DO.SectionTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: row.cellClass),
            for: indexPath
        )
        row.configure(cell)

        (cell as? DO.SectionCell)?.sectionDelegate = self
        return cell
    }
}

extension DO.SectionTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section].title else { return nil }

        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: DO.SectionHeaderView.self)
        ) as? DO.SectionHeaderView
        header?.titleLabel.text = title
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let title = sections[section].footer else { return nil }

        let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: DO.SectionFooterView.self)
        ) as? DO.SectionFooterView
        footer?.titleLabel.text = title
        return footer
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].title != nil ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        sections[section].footer != nil ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
    }
}
