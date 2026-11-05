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

    /// The log list. Not a `SectionTableViewController`: one homogeneous row type, and a flat
    /// separator-less table reads as one continuous block of text.
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
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            return label
        }()

        private lazy var searchController: UISearchController = {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.placeholder = DO.Text.Console.searchPlaceholder
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

        /// Capture is explicit: the pipe takes over fd 1 and fd 2, so it must never be attached
        /// behind the caller's back.
        private lazy var captureItem = UIBarButtonItem(
            image: UIImage(systemName: "record.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleCapture)
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

            title = DO.Text.Console.title

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
                spacer(), captureItem, spacer(), unifiedLogItem, spacer(),
                pauseItem, spacer(), clearItem, spacer(), exportItem, spacer(),
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
                emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
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
                emptyLabel.text = DO.Text.Console.emptyNothing
            } else {
                emptyLabel.text = DO.Text.Console.emptyAllFiltered(store.capturedCount)
            }
        }

        private func updateToolbarItems() {
            let store = DO.ConsoleStore.shared

            pauseItem.image = UIImage(systemName: store.isPaused ? "play.fill" : "pause")
            pauseItem.accessibilityLabel = store.isPaused ? DO.Text.Console.resume : DO.Text.Console.pause

            clearItem.isEnabled = store.capturedCount > 0
            exportItem.isEnabled = store.capturedCount > 0

            captureItem.image = UIImage(systemName: store.isCapturing ? "stop.circle" : "record.circle")
            captureItem.tintColor = store.isCapturing ? .systemRed : nil
            captureItem.accessibilityLabel = store.isCapturing ? DO.Text.Common.stopCapture : DO.Text.Common.startCapture

            let refreshing = store.unifiedLog.isRefreshing
            unifiedLogItem.isEnabled = !refreshing && DO.ConsoleUnifiedLog.isAvailable
            unifiedLogItem.accessibilityLabel = refreshing ? DO.Text.Console.readingUnifiedLog : DO.Text.Console.readUnifiedLog
        }

        private var statusText: String {
            let store = DO.ConsoleStore.shared

            let sources = DO.ConsoleLine.Source.allCases.filter {
                $0 != .unifiedLog || DO.ConsoleUnifiedLog.isAvailable
            }

            var counts = [DO.Text.Console.totalLines(store.capturedCount)]
            for source in sources {
                counts.append(DO.Text.Console.sourceCount(source.shortTitle, store.capturedCount(of: source)))
            }

            var parts = [counts.joined(separator: "  ")]

            if store.filter.sources.count < sources.count {
                parts.append(DO.Text.Console.filteredSources(store.filter.sources.count, sources.count))
            }

            if !store.isCapturing { parts.append(DO.Text.Console.captureOff) }

            if store.isPaused { parts.append(DO.Text.Console.paused) }

            if !DO.ConsoleUnifiedLog.isAvailable {
                parts.append(DO.Text.Console.unifiedLogNeedsIOS15)
            } else if store.unifiedLog.isRefreshing {
                parts.append(DO.Text.Console.readingUnifiedLogStatus)
            } else if store.unifiedLog.lastDuration > 0 {
                parts.append(DO.Text.Console.readIn(store.unifiedLog.lastDuration))
            }

            return parts.joined(separator: "  ·  ")
        }

        @objc private func showSettings() {
            navigationController?.pushViewController(DO.ConsoleSettingViewController(), animated: true)
        }

        @objc private func toggleCapture() {
            let store = DO.ConsoleStore.shared

            if store.isCapturing {
                store.stopCollecting()
            } else {
                store.startCollecting()
            }

            reload()
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
                message: DO.Text.Console.clearConfirmation(count),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: DO.Text.Common.cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: DO.Text.Common.clear, style: .destructive) { _ in
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        ) as? DO.ConsoleLineCell else {
            return UITableViewCell()
        }

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
