//
//  FileListView.swift
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

    /// Event outlet of ``DO.FileListView``.
    protocol FileListViewDelegate: AnyObject {

        /// Row `index` was tapped; indices only, no business models.
        func fileListView(_ list: DO.FileListView, didSelectAt index: Int)

        /// Whether row `index` can be swiped to delete; `false` by default.
        func fileListView(_ list: DO.FileListView, canDeleteAt index: Int) -> Bool

        /// Delete confirmed for row `index` — reload after deleting.
        func fileListView(_ list: DO.FileListView, didDeleteAt index: Int)
    }

    /// Dumb list: draws what it is given and reports row indices only. No path stack,
    /// no loading state; the public contract is `[any DO.FileNode]`, never `IndexPath` or cells.
    @objc(DOFileListView)
    final class FileListView: UIView {

        weak var delegate: (any DO.FileListViewDelegate)?

        /// Current rows, in display order.
        private(set) var nodes: [any DO.FileNode] = []

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Interface

        func update(_ nodes: [any DO.FileNode]) {
            self.nodes = nodes

            tableView.reloadData()
        }

        // MARK: - View

        private func loadViews(in box: UIView) {
            backgroundColor = DO.FileBrowserStyle.backgroundColor

            box.addSubview(tableView)
            tableView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: box.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            ])

            /// Drop the last separator instead of threading "is last" through the call chain.
            tableView.tableFooterView = UIView()
        }

        // MARK: - Subviews

        private lazy var tableView: UITableView = {
            let view = UITableView(frame: .zero, style: .plain)
            view.dataSource = self
            view.delegate = self
            view.register(DO.FileBrowserNodeCell.self, forCellReuseIdentifier: Self.cellIdentifier)
            view.backgroundColor = .clear
            /// Let the row view size itself.
            view.rowHeight = UITableView.automaticDimension
            view.estimatedRowHeight = 64.0
            view.separatorInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0)
            return view
        }()

        private static let cellIdentifier = String(describing: DO.FileBrowserNodeCell.self)
    }
}

extension DO.FileListViewDelegate {

    /// Read-only by default.
    func fileListView(_ list: DO.FileListView, canDeleteAt index: Int) -> Bool {
        return false
    }

    /// Nothing to do by default.
    func fileListView(_ list: DO.FileListView, didDeleteAt index: Int) {}
}

extension DO.FileListView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        ) as? DO.FileBrowserNodeCell
        if let cell = cell, nodes.indices.contains(indexPath.row) {
            cell.config(node: nodes[indexPath.row])
        }
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard nodes.indices.contains(indexPath.row) else { return }
        delegate?.fileListView(self, didSelectAt: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard nodes.indices.contains(indexPath.row),
              (delegate?.fileListView(self, canDeleteAt: indexPath.row) ?? false) else {
            return nil
        }

        let action = UIContextualAction(style: .destructive, title: DO.Text.Common.delete) { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            completion(true)
            self.delegate?.fileListView(self, didDeleteAt: indexPath.row)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
