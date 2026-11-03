//
//  UserDefaultsViewController.swift
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

    @objc(DOUserDefaultsViewController)
    final class UserDefaultsViewController: DO.SectionTableViewController {

        private var snapshot: DO.UserDefaultsSnapshot = .capture()

        private var visibleItems: [[DO.UserDefaultsSnapshot.Item]] = []

        private var keyword: String = ""

        private lazy var searchController: UISearchController = {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.placeholder = "Search by key"
            return controller
        }()

        private lazy var deleteItem = UIBarButtonItem(
            title: "Delete",
            style: .plain,
            target: self,
            action: #selector(deleteSelected)
        )

        private lazy var selectAllItem = UIBarButtonItem(
            title: "Select All",
            style: .plain,
            target: self,
            action: #selector(toggleSelectAll)
        )

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "UserDefaults"

            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.searchController = searchController
            navigationItem.rightBarButtonItem = editButtonItem

            tableView.allowsMultipleSelectionDuringEditing = true
            navigationController?.setToolbarHidden(true, animated: false)

            reloadSections()
        }

        override func close() {
            DO.UserDefaultsPlugin.shared.hide()
        }

        func refresh() {
            setEditing(false, animated: false)
            searchController.isActive = false
            view.endEditing(true)

            snapshot = .capture()
            reloadSections()
        }

        private func reloadSections() {
            let filtered = snapshot.filtered(by: keyword)
            visibleItems = filtered.domains.map(\.items)

            sections = filtered.domains.map { domain in
                Section(title: domain.title, rows: domain.items.map { item in
                    Row(
                        cellClass: DO.SelectorCell.self,
                        onTrigger: { [weak self] _ in
                            guard let self = self, !self.isEditing else { return }
                            self.showDetail(item)
                        }
                    ) { cell in
                        cell.detailNumberOfLines = 1
                        cell.update(title: item.key, detail: item.summary)
                    }
                })
            }
        }

        private func showDetail(_ item: DO.UserDefaultsSnapshot.Item) {
            let detail = DO.PlainTextViewController(title: item.key, text: item.fullText)
            navigationController?.pushViewController(detail, animated: true)
        }

        private func delete(_ items: [DO.UserDefaultsSnapshot.Item]) {
            items.forEach { UserDefaults.standard.removeObject(forKey: $0.key) }

            snapshot = .capture()
            reloadSections()

            updateBatchItems()
        }

        private func item(at indexPath: IndexPath) -> DO.UserDefaultsSnapshot.Item? {
            guard visibleItems.indices.contains(indexPath.section),
                  visibleItems[indexPath.section].indices.contains(indexPath.row) else { return nil }
            return visibleItems[indexPath.section][indexPath.row]
        }

        override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)

            tableView.setEditing(editing, animated: animated)

            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = editing ? [selectAllItem, spacer, deleteItem] : []
            navigationController?.setToolbarHidden(!editing, animated: animated)

            updateBatchItems()
        }

        private func updateBatchItems() {
            let selected = tableView.indexPathsForSelectedRows?.count ?? 0
            let total = allIndexPaths.count

            deleteItem.isEnabled = selected > 0
            deleteItem.title = selected > 0 ? "Delete (\(selected))" : "Delete"

            selectAllItem.isEnabled = total > 0
            selectAllItem.title = (total > 0 && selected == total) ? "Deselect All" : "Select All"
        }

        private var allIndexPaths: [IndexPath] {
            sections.indices.flatMap { section in
                sections[section].rows.indices.map { IndexPath(row: $0, section: section) }
            }
        }

        @objc private func toggleSelectAll() {
            let all = allIndexPaths
            let selected = tableView.indexPathsForSelectedRows?.count ?? 0
            let deselecting = !all.isEmpty && selected == all.count

            for indexPath in all {
                if deselecting {
                    tableView.deselectRow(at: indexPath, animated: false)
                } else {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }

            updateBatchItems()
        }

        @objc private func deleteSelected() {
            let items = (tableView.indexPathsForSelectedRows ?? []).compactMap(item(at:))
            guard !items.isEmpty else { return }

            let alert = UIAlertController(
                title: nil,
                message: "Delete \(items.count) key\(items.count > 1 ? "s" : "")?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.setEditing(false, animated: true)
                self?.delete(items)
            })
            present(alert, animated: true)
        }
    }

}

extension DO.UserDefaultsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive, isEditing {
            setEditing(false, animated: false)
        }

        keyword = searchController.searchBar.text ?? ""
        reloadSections()
    }
}

extension DO.UserDefaultsViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        updateBatchItems()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        updateBatchItems()
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let item = item(at: indexPath) else { return nil }

        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.delete([item])
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
