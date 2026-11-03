//
//  NetworkViewController.swift
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

    /// The request list: newest first, refreshed once a second while visible.
    @objc(DONetworkViewController)
    final class NetworkViewController: DO.SectionTableViewController {

        private var timer: Timer?

        /// Fingerprint of what is on screen: rebuilding on every tick drops a tap that spans a
        /// tick and resets the scroll position.
        private var signature: String = ""

        override func viewDidLoad() {
            super.viewDidLoad()

            title = DO.Text.Network.title
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: DO.Text.Common.clear,
                style: .plain,
                target: self,
                action: #selector(handleClear)
            )
        }

        /// The list is the window's root; dismissing would leave the window on screen.
        override func close() {
            DO.NetworkPlugin.shared.hide()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            reload()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.reload()
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            timer?.invalidate()
            timer = nil
        }

        func reload(force: Bool = false) {
            let capture = DO.NetworkCapture.shared
            let records = Array(capture.snapshot().reversed())

            let current = "\(capture.isEnabled)|\(records.count)|\(records.first?.id ?? -1)|\(records.last?.id ?? -1)"
            guard force || current != signature else { return }
            signature = current

            var sections: [Section] = [
                Section(rows: [
                    Row(cellClass: DO.ActionCell.self, onTrigger: { [weak self] _ in
                        if capture.isEnabled {
                            capture.stop()
                        } else {
                            capture.start()
                        }
                        self?.reload(force: true)
                    }) { cell in
                        cell.update(
                            title: capture.isEnabled ? DO.Text.Common.stopCapture : DO.Text.Common.startCapture,
                            isDestructive: capture.isEnabled
                        )
                    }
                ])
            ]

            if records.isEmpty {
                sections.append(Section(
                    footer: DO.Text.Network.emptyFooter,
                    rows: []
                ))
            } else {
                sections.append(Section(title: DO.Text.Network.requests(records.count), rows: records.map { row(for: $0) }))
            }

            self.sections = sections
        }

        private func row(for record: DO.NetworkRecord) -> Row {
            return Row(cellClass: DO.KeyValueCell.self, onTrigger: { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.pushViewController(
                    DO.NetworkDetailViewController(record: record),
                    animated: true
                )
            }) { cell in
                cell.update(
                    title: "\(record.method)  \(Self.path(of: record.url))",
                    detail: Self.detail(of: record)
                )
                cell.selectionStyle = .default
            }
        }

        @objc private func handleClear() {
            DO.NetworkCapture.shared.clear()
            reload(force: true)
        }

        private static func path(of url: URL?) -> String {
            guard let url = url else { return "-" }
            let path = url.path.isEmpty ? "/" : url.path
            guard let query = url.query, !query.isEmpty else { return path }
            return path + "?" + query
        }

        private static func detail(of record: DO.NetworkRecord) -> String {
            var parts: [String] = []

            if let status = record.status {
                parts.append("\(status)")
            } else {
                parts.append(record.error == nil ? "-" : DO.Text.Network.failed)
            }
            if let duration = record.duration {
                parts.append(String(format: "%.0f ms", duration * 1000))
            }
            if let body = record.responseBody {
                parts.append(size(body.byteCount))
            }
            parts.append(time(record.start))
            return parts.joined(separator: "  ·  ")
        }

        private static func size(_ bytes: Int) -> String {
            if bytes < 1024 { return "\(bytes) B" }
            if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
            return String(format: "%.1f MB", Double(bytes) / 1024 / 1024)
        }

        private static func time(_ timestamp: TimeInterval) -> String {
            let date = Date(timeIntervalSinceNow: timestamp - CACurrentMediaTime())
            return formatter.string(from: date)
        }

        private static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()
    }
}
