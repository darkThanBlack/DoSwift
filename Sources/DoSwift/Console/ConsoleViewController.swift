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

    @objc(DOConsoleViewController)
    final class ConsoleViewController: DO.SectionTableViewController {

        private var lines: [DO.ConsoleLine] = []

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

            navigationController?.setToolbarHidden(false, animated: false)

            let spacer = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
            toolbarItems = [
                spacer(), unifiedLogItem, spacer(), pauseItem, spacer(), clearItem, spacer(), exportItem, spacer(),
            ]

            DO.ConsoleStore.shared.onChange = { [weak self] in
                self?.reloadSections()
            }
            DO.ConsoleStore.shared.unifiedLog.onStateChange = { [weak self] in
                self?.updateToolbarItems()
            }

            reloadSections()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            navigationController?.setToolbarHidden(false, animated: animated)
        }

        override func close() {
            DO.ConsolePlugin.shared.hide()
        }

        func refresh() {
            searchController.isActive = false
            view.endEditing(true)
            reloadSections()
        }

        private func reloadSections() {
            lines = DO.ConsoleStore.shared.visibleLines()

            sections = [
                Section(footer: statusText, rows: lines.map { line in
                    Row(
                        cellClass: DO.SelectorCell.self,
                        onTrigger: { [weak self] _ in
                            self?.showDetail(line)
                        }
                    ) { cell in
                        cell.titleNumberOfLines = 1
                        cell.detailNumberOfLines = 1
                        cell.update(title: line.rowTitle, detail: line.metaText)
                    }
                })
            ]

            updateToolbarItems()
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

        private func showDetail(_ line: DO.ConsoleLine) {
            let detail = DO.PlainTextViewController(title: line.timeText, text: line.fullText)
            navigationController?.pushViewController(detail, animated: true)
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

extension DO.ConsoleViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        DO.ConsoleStore.shared.filter.keyword = searchController.searchBar.text ?? ""
    }
}
