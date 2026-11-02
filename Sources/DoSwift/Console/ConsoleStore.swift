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

        func startCollecting() {
            capture.start()
        }

        struct Filter {
            var sources: Set<DO.ConsoleLine.Source> = Set(DO.ConsoleLine.Source.allCases)

            var keyword: String = ""

            var includesEmptySubsystem: Bool = true
        }

        var filter = Filter() {
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

        func append(_ line: DO.ConsoleLine) {
            lock.lock()
            guard !pausedStorage else {
                lock.unlock()
                return
            }

            var line = line
            line.setText(line.text, limit: maxTextLength)

            // Same timestamp and same source means one write that happened to contain several
            // lines: keep them as one block instead of a dozen near-identical rows.
            if let last = buffer.last,
               last.source == line.source,
               last.level == line.level,
               last.timeText == line.timeText {
                var merged = last
                merged.appendContinuation(line.text, limit: maxTextLength)
                buffer[buffer.count - 1] = merged
            } else {
                buffer.append(line)
                if buffer.count > limit {
                    buffer.removeFirst(buffer.count - limit)
                }
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

        func visibleLines() -> [DO.ConsoleLine] {
            lock.lock()
            let snapshot = buffer
            lock.unlock()

            let keyword = filter.keyword.trimmingCharacters(in: .whitespaces).lowercased()
            let filtered = snapshot.filter { line in
                guard filter.sources.contains(line.source) else { return false }
                // Unified log entries without a subsystem cannot be attributed to anyone;
                // this is the only thing that hides them.
                if !filter.includesEmptySubsystem,
                   line.source == .unifiedLog,
                   (line.subsystem ?? "").isEmpty {
                    return false
                }
                guard !keyword.isEmpty else { return true }
                return line.text.lowercased().contains(keyword)
            }
            return filtered.reversed()
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
