//
//  ConsoleStore.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    final class ConsoleStore {

        static let shared = DO.ConsoleStore()

        private init() {
            capture.onLine = { [weak self] line in
                self?.append(line)
            }
            capture.onContinuation = { [weak self] source, text in
                self?.appendContinuation(text, from: source)
            }
            unifiedLog.onLines = { [weak self] lines in
                lines.forEach { self?.append($0) }
            }
        }

        let capture = DO.ConsoleCapture.shared

        let unifiedLog = DO.ConsoleUnifiedLog()

        /// Whether the fd pipe is attached right now. Display pausing is `isPaused`, unrelated.
        var isCapturing: Bool {
            capture.isRunning
        }

        func startCollecting() {
            capture.start()
            notify()
        }

        func stopCollecting() {
            capture.stop()
            notify()
        }

        struct Filter {
            var sources: Set<DO.ConsoleLine.Source> = Set(DO.ConsoleLine.Source.allCases)

            var keyword: String = ""

            var includesEmptySubsystem: Bool = true
        }

        var filter = Filter() {
            didSet { notify() }
        }

        /// Sources whose consecutive same-timestamp lines fold into one block. Default: stderr —
        /// `NSLog` dumps a whole object as one message. Not `print`, not the unified log.
        var mergesSameTimestamp: Set<DO.ConsoleLine.Source> = [.standardError] {
            didSet { notify() }
        }

        private var pausedStorage = false

        var isPaused: Bool {
            get {
                lock.lock()
                defer { lock.unlock() }
                return pausedStorage
            }
            set {
                lock.lock()
                pausedStorage = newValue
                lock.unlock()

                notify()
            }
        }

        private let limit = 2000

        private let maxTextLength = 4000

        private let lock = NSLock()

        var onChange: (() -> Void)?

        private var buffer: [DO.ConsoleLine] = []

        /// Per-source counts kept in step with `buffer`, so the status bar does not walk the buffer.
        private var sourceCounts: [DO.ConsoleLine.Source: Int] = [:]

        func append(_ line: DO.ConsoleLine) {
            lock.lock()
            guard !pausedStorage else {
                lock.unlock()
                return
            }

            var line = line
            line.setText(line.text, limit: maxTextLength)
            buffer.append(line)
            sourceCounts[line.source, default: 0] += 1

            if buffer.count > limit {
                let overflow = buffer.count - limit
                for evicted in buffer.prefix(overflow) {
                    sourceCounts[evicted.source, default: 0] -= 1
                }
                buffer.removeFirst(overflow)
            }
            lock.unlock()

            notify()
        }

        func appendContinuation(_ text: String, from source: DO.ConsoleLine.Source) {
            lock.lock()
            if !pausedStorage, let last = buffer.last, last.source == source {
                var merged = last
                merged.appendContinuation(text, limit: maxTextLength)
                buffer[buffer.count - 1] = merged
                lock.unlock()

                notify()
                return
            }
            lock.unlock()

            append(DO.ConsoleLine(date: Date(), source: source, text: text))
        }

        var capturedCount: Int {
            lock.lock()
            defer { lock.unlock() }
            return buffer.count
        }

        /// How many lines of this source are currently kept.
        func capturedCount(of source: DO.ConsoleLine.Source) -> Int {
            lock.lock()
            defer { lock.unlock() }
            return sourceCounts[source] ?? 0
        }

        func visibleLines() -> [DO.ConsoleLine] {
            lock.lock()
            let snapshot = buffer
            lock.unlock()

            let filter = self.filter
            let mergeable = mergesSameTimestamp

            let shown = snapshot.filter { line in
                guard filter.sources.contains(line.source) else { return false }
                // Empty subsystem belongs to nobody; this toggle is the only thing that hides them.
                if !filter.includesEmptySubsystem,
                   line.source == .unifiedLog,
                   (line.subsystem ?? "").isEmpty {
                    return false
                }
                return true
            }

            // Merged at read time, so flipping the switch re-groups what is already captured.
            let merged = merge(shown, sources: mergeable)

            let keyword = filter.keyword.trimmingCharacters(in: .whitespaces).lowercased()
            let filtered = keyword.isEmpty
                ? merged
                : merged.filter { $0.text.lowercased().contains(keyword) }
            return filtered.reversed()
        }

        /// Folds consecutive lines that share a timestamp, a source and a level.
        private func merge(
            _ lines: [DO.ConsoleLine],
            sources: Set<DO.ConsoleLine.Source>
        ) -> [DO.ConsoleLine] {
            guard !sources.isEmpty else { return lines }

            var result: [DO.ConsoleLine] = []
            result.reserveCapacity(lines.count)

            for line in lines {
                guard sources.contains(line.source),
                      let last = result.last,
                      last.source == line.source,
                      last.level == line.level,
                      last.timeText == line.timeText else {
                    result.append(line)
                    continue
                }

                var merged = last
                merged.appendContinuation(line.text, limit: maxTextLength)
                result[result.count - 1] = merged
            }
            return result
        }

        func exportText() -> String {
            lock.lock()
            let snapshot = buffer
            lock.unlock()

            return snapshot
                .map { "[\($0.metaText)] \($0.text)" }
                .joined(separator: "\n")
        }

        func clear() {
            lock.lock()
            buffer.removeAll()
            sourceCounts.removeAll()
            lock.unlock()

            notify()
        }

        private let notifyLock = NSLock()
        private var isNotifyScheduled = false
        private var lastNotify = Date.distantPast

        private let minNotifyInterval: TimeInterval = 0.2

        private func notify() {
            notifyLock.lock()
            if isNotifyScheduled {
                notifyLock.unlock()
                return
            }
            isNotifyScheduled = true

            let wait = minNotifyInterval - Date().timeIntervalSince(lastNotify)
            notifyLock.unlock()

            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, wait)) { [weak self] in
                guard let self = self else { return }
                self.notifyLock.lock()
                self.isNotifyScheduled = false
                self.lastNotify = Date()
                self.notifyLock.unlock()

                self.onChange?()
            }
        }
    }
}
