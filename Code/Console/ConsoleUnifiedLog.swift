//
//  ConsoleUnifiedLog.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation
import OSLog

extension DO {

    final class ConsoleUnifiedLog {

        static var isAvailable: Bool {
            if #available(iOS 15.0, *) { return true }
            return false
        }

        var subsystem = Bundle.main.bundleIdentifier ?? ""

        var onLines: (([DO.ConsoleLine]) -> Void)?

        var onStateChange: (() -> Void)?

        private(set) var lastDuration: TimeInterval = 0

        private(set) var isRefreshing = false

        private let queryQueue = DispatchQueue(label: "com.doswift.console.unifiedlog")

        private var lastDate: Date?

        func refresh() {
            guard #available(iOS 15.0, *) else { return }
            guard !isRefreshing else { return }

            isRefreshing = true
            onStateChange?()

            queryQueue.async { [weak self] in
                guard let self = self else { return }
                let started = Date()
                let lines = self.query()
                let elapsed = Date().timeIntervalSince(started)

                if !lines.isEmpty { self.onLines?(lines) }

                DispatchQueue.main.async {
                    self.lastDuration = elapsed
                    self.isRefreshing = false
                    self.onStateChange?()
                }
            }
        }

        @available(iOS 15.0, *)
        private func query() -> [DO.ConsoleLine] {
            let last = lastDate ?? Date()
            lastDate = last

            guard let store = try? OSLogStore(scope: .currentProcessIdentifier),
                  let entries = try? store.getEntries(at: store.position(date: last)) else {
                return []
            }

            var lines: [DO.ConsoleLine] = []
            for entry in entries {
                guard let log = entry as? OSLogEntryLog else { continue }
                // Empty subsystem = a bare `Logger()`, ours or a framework's; read all, let the filter decide.
                guard log.subsystem == subsystem || log.subsystem.isEmpty else { continue }

                guard entry.date > last else { continue }

                lines.append(
                    DO.ConsoleLine(
                        date: entry.date,
                        source: .unifiedLog,
                        text: entry.composedMessage,
                        level: DO.ConsoleLine.Level(rawValue: log.level.rawValue),
                        subsystem: log.subsystem,
                        category: log.category
                    )
                )
            }

            guard !lines.isEmpty else { return [] }

            lastDate = lines.map(\.date).max() ?? last
            return lines.sorted { $0.date < $1.date }
        }
    }
}
