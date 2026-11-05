//
//  NetworkDetailViewController.swift
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

    /// One request, read-only. Long payloads open in `DO.PlainTextViewController`.
    @objc(DONetworkDetailViewController)
    final class NetworkDetailViewController: DO.SectionTableViewController {

        private let record: DO.NetworkRecord

        init(record: DO.NetworkRecord) {
            self.record = record
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            // Pushed, not presented: the base class's close button would replace the back button.
            navigationItem.leftBarButtonItem = nil

            title = record.url?.host ?? DO.Text.Network.title
            loadSections()
        }

        private func loadSections() {
            sections = [
                Section(title: DO.Text.Network.overviewSection, rows: [
                    valueRow(DO.Text.Network.rowURL, record.url?.absoluteString ?? "-"),
                    valueRow(DO.Text.Network.rowMethod, record.method),
                    valueRow(DO.Text.Network.rowStatus, statusText),
                    valueRow(DO.Text.Network.rowDuration, record.duration.map { String(format: "%.1f ms", $0 * 1000) } ?? "-"),
                ]),
                Section(title: DO.Text.Network.requestSection, rows: [
                    textRow(DO.Text.Network.requestHeaders, text: headersText(record.requestHeaders)),
                    textRow(DO.Text.Network.requestBody, text: bodyText(record.requestBody)),
                ]),
                Section(title: DO.Text.Network.responseSection, rows: [
                    textRow(DO.Text.Network.responseHeaders, text: headersText(record.responseHeaders)),
                    textRow(DO.Text.Network.responseBody, text: bodyText(record.responseBody)),
                ]),
            ]
        }

        private var statusText: String {
            if let status = record.status { return "\(status)" }
            return record.error ?? "-"
        }

        private func valueRow(_ title: String, _ detail: String) -> Row {
            return Row(cellClass: DO.KeyValueCell.self) { cell in
                cell.update(title: title, detail: detail)
            }
        }

        private func textRow(_ title: String, text: String?) -> Row {
            return Row(cellClass: DO.KeyValueCell.self, onTrigger: { [weak self] _ in
                guard let text = text else { return }
                self?.navigationController?.pushViewController(
                    DO.PlainTextViewController(title: title, text: text),
                    animated: true
                )
            }) { cell in
                cell.update(title: title, detail: text.map(Self.summary(of:)) ?? DO.Text.Network.none)
                cell.selectionStyle = text == nil ? .none : .default
            }
        }

        private static func summary(of text: String) -> String {
            let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
            return firstLine.isEmpty ? DO.Text.Network.view : String(firstLine.prefix(80))
        }

        private func headersText(_ headers: [String: String]) -> String? {
            guard !headers.isEmpty else { return nil }
            return headers
                .sorted { $0.key.lowercased() < $1.key.lowercased() }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }

        private func bodyText(_ body: DO.NetworkBody?) -> String? {
            guard let body = body else { return nil }

            guard let text = body.text else {
                return DO.Text.Network.binaryBody(body.byteCount)
            }

            var result = text
            if let data = text.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
               let string = String(data: pretty, encoding: .utf8) {
                result = string
            }

            if body.truncated {
                result += DO.Text.Network.truncatedBody(maxBytes: DO.NetworkBody.maxBytes)
            }
            return result
        }
    }
}
