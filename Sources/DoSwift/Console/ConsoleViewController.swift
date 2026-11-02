//
//  ConsoleViewController.swift
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

    /// The log list.
    ///
    /// Deliberately not a `SectionTableViewController`: this screen has one homogeneous kind of
    /// row and wants a flat, card-less look, while the base class exists for grouped settings
    /// panels. A plain table with no separators and 3pt row spacing reads as one continuous
    /// block of text.
    @objc(DOConsoleViewController)
    final class ConsoleViewController: UIViewController {

        private static let cellIdentifier = "line"

        private var lines: [DO.ConsoleLine] = []

        private lazy var tableView: UITableView = {
            let tableView = UITableView(frame: .zero, style: .plain)
            tableView.dataSource = self
            tableView.delegate = self
            tableView.separatorStyle = .none
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 32
            tableView.backgroundColor = .systemBackground
            tableView.keyboardDismissMode = .onDrag
            tableView.register(DO.ConsoleLineCell.self, forCellReuseIdentifier: Self.cellIdentifier)
            return tableView
        }()

        /// Shown over the table when nothing is listed, so "empty" never has to be guessed at.
        private let emptyLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.numberOfLines = 0
            label.isHidden = true
            return label
        }()

        private let statusLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 1
            return label
        }()

        private lazy var searchController: UISearchController = {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.placeholder = "Search lines"
            return controller
        }()

        private lazy var settingItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )

        private lazy var pauseItem = UIBarButtonItem(
            image: UIImage(systemName: "pause"),
            style: .plain,
            target: self,
            action: #selector(togglePause)
        )

        private lazy var unifiedLogItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshUnifiedLog)
        )

        private lazy var clearItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clear)
        )

        private lazy var exportItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(export)
        )

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "Console"

            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.searchController = searchController
            navigationItem.rightBarButtonItem = settingItem
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(close)
            )

            navigationController?.setToolbarHidden(false, animated: false)

            let spacer = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
            toolbarItems = [
                spacer(), unifiedLogItem, spacer(), pauseItem, spacer(), clearItem, spacer(), exportItem, spacer(),
            ]

            view.backgroundColor = .systemBackground
            tableView.translatesAutoresizingMaskIntoConstraints = false
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tableView)
            view.addSubview(statusLabel)

            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyLabel)

            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
                emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor),

                statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -2),
            ])

            DO.ConsoleStore.shared.onChange = { [weak self] in
                self?.reload()
            }
            DO.ConsoleStore.shared.unifiedLog.onStateChange = { [weak self] in
                self?.updateToolbarItems()
            }

            reload()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            navigationController?.setToolbarHidden(false, animated: animated)
        }

        @objc func close() {
            DO.ConsolePlugin.shared.hide()
        }

        /// Called by the plugin every time the window is shown.
        func refresh() {
            searchController.isActive = false
            view.endEditing(true)
            reload()
        }

        private func reload() {
            let store = DO.ConsoleStore.shared
            lines = store.visibleLines()

            tableView.reloadData()
            updateEmptyState()
            statusLabel.text = statusText
            updateToolbarItems()
        }

        private func updateEmptyState() {
            let store = DO.ConsoleStore.shared
            emptyLabel.isHidden = !lines.isEmpty

            if store.capturedCount == 0 {
                emptyLabel.text = "Nothing captured yet.\n"
                    + "print() and NSLog are only picked up once this page is open —\n"
                    + "call DO.ConsolePlugin.shared.startCapture() at launch to keep the whole session."
            } else {
                emptyLabel.text = "All \(store.capturedCount) captured lines are hidden by the filter.\n"
                    + "Check Settings → Sources."
            }
        }

        private func updateToolbarItems() {
            let store = DO.ConsoleStore.shared

            pauseItem.image = UIImage(systemName: store.isPaused ? "play.fill" : "pause")
            pauseItem.accessibilityLabel = store.isPaused ? "Resume" : "Pause"

            clearItem.isEnabled = store.capturedCount > 0
            exportItem.isEnabled = store.capturedCount > 0

            let refreshing = store.unifiedLog.isRefreshing
            unifiedLogItem.isEnabled = !refreshing && DO.ConsoleUnifiedLog.isAvailable
            unifiedLogItem.accessibilityLabel = refreshing ? "Reading Unified Log" : "Read Unified Log"
        }

        private var statusText: String {
            let store = DO.ConsoleStore.shared
            var parts = ["\(lines.count) of \(store.capturedCount) lines"]

            let total = DO.ConsoleLine.Source.allCases.filter {
                $0 != .unifiedLog || DO.ConsoleUnifiedLog.isAvailable
            }.count
            if store.filter.sources.count < total {
                parts.append("\(store.filter.sources.count)/\(total) sources")
            }

            if store.isPaused { parts.append("paused") }

            if !DO.ConsoleUnifiedLog.isAvailable {
                parts.append("Unified Log needs iOS 15")
            } else if store.unifiedLog.isRefreshing {
                parts.append("reading unified log…")
            } else if store.unifiedLog.lastDuration > 0 {
                parts.append(String(format: "unified log read in %.1fs", store.unifiedLog.lastDuration))
            }

            return parts.joined(separator: " · ")
        }

        @objc private func showSettings() {
            navigationController?.pushViewController(DO.ConsoleSettingViewController(), animated: true)
        }

        @objc private func togglePause() {
            DO.ConsoleStore.shared.isPaused.toggle()
        }

        @objc private func refreshUnifiedLog() {
            DO.ConsoleStore.shared.unifiedLog.refresh()
        }

        @objc private func clear() {
            let count = DO.ConsoleStore.shared.capturedCount
            guard count > 0 else { return }

            let alert = UIAlertController(
                title: nil,
                message: "Clear \(count) line\(count > 1 ? "s" : "")?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
                DO.ConsoleStore.shared.clear()
            })
            present(alert, animated: true)
        }

        @objc private func export() {
            let text = DO.ConsoleStore.shared.exportText()
            guard !text.isEmpty else { return }

            let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            activity.popoverPresentationController?.barButtonItem = exportItem
            present(activity, animated: true)
        }
    }
}

extension DO.ConsoleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        ) as! DO.ConsoleLineCell

        cell.sectionDelegate = self
        cell.update(lines[indexPath.row])
        return cell
    }
}

extension DO.ConsoleViewController: UITableViewDelegate {}

extension DO.ConsoleViewController: DO.SectionCellDelegate {

    func sectionCellDidTrigger(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        UIPasteboard.general.string = lines[indexPath.row].copyText
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let indexPath = self.tableView.indexPath(for: cell) else { return }
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension DO.ConsoleViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        DO.ConsoleStore.shared.filter.keyword = searchController.searchBar.text ?? ""
    }
}
