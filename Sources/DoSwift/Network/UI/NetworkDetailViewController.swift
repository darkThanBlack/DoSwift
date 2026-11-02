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

    /// One request, read-only. Long payloads open in `DO.PlainTextViewController` so the list
    /// stays scannable.
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

            // This page is pushed, so the close button the base class installs would replace
            // the back button and do nothing when tapped.
            navigationItem.leftBarButtonItem = nil

            title = record.url?.host ?? "网络"
            loadSections()
        }

        private func loadSections() {
            sections = [
                Section(title: "概要", rows: [
                    valueRow("URL", record.url?.absoluteString ?? "-"),
                    valueRow("Method", record.method),
                    valueRow("Status", statusText),
                    valueRow("Duration", record.duration.map { String(format: "%.1f ms", $0 * 1000) } ?? "-"),
                ]),
                Section(title: "请求", rows: [
                    textRow("请求头", text: headersText(record.requestHeaders)),
                    textRow("请求体", text: bodyText(record.requestBody)),
                ]),
                Section(title: "响应", rows: [
                    textRow("响应头", text: headersText(record.responseHeaders)),
                    textRow("响应体", text: bodyText(record.responseBody)),
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
                cell.update(title: title, detail: text == nil ? "无" : Self.summary(of: text!))
                cell.selectionStyle = text == nil ? .none : .default
            }
        }

        private static func summary(of text: String) -> String {
            let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
            return firstLine.isEmpty ? "查看" : String(firstLine.prefix(80))
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
                return "<\(body.byteCount) bytes of binary data>"
            }

            var result = text
            if let data = text.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
               let string = String(data: pretty, encoding: .utf8) {
                result = string
            }

            if body.truncated {
                result += "\n\n… 已截断，只保留前 \(DO.NetworkBody.maxBytes) 字节"
            }
            return result
        }
    }
}
