//
//  ConsoleLine.swift
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

    struct ConsoleLine {

        enum Source: String, Codable, CaseIterable {

            case standardOutput
            case standardError
            case unifiedLog

            var title: String {
                switch self {
                case .standardOutput: return DO.Text.Console.standardOutput
                case .standardError:  return DO.Text.Console.standardError
                case .unifiedLog:     return DO.Text.Console.unifiedLog
                }
            }

            /// Short tag used by the flat list: what the fd actually is.
            var shortTitle: String {
                switch self {
                case .standardOutput: return "fd1"
                case .standardError:  return "fd2"
                case .unifiedLog:     return "oslog"
                }
            }

            var detail: String {
                switch self {
                case .standardOutput: return DO.Text.Console.standardOutputDetail
                case .standardError:  return DO.Text.Console.standardErrorDetail
                case .unifiedLog:     return DO.Text.Console.unifiedLogDetail
                }
            }
        }

        enum Level: Int, CaseIterable {
            case debug = 1
            case info = 2
            case notice = 3
            case error = 4
            case fault = 5

            var title: String {
                switch self {
                case .debug:  return DO.Text.Console.levelDebug
                case .info:   return DO.Text.Console.levelInfo
                case .notice: return DO.Text.Console.levelNotice
                case .error:  return DO.Text.Console.levelError
                case .fault:  return DO.Text.Console.levelFault
                }
            }
        }

        let date: Date
        let source: Source
        var text: String
        var level: Level?
        var subsystem: String?
        var category: String?

        let timeText: String

        init(
            date: Date,
            source: Source,
            text: String,
            level: Level? = nil,
            subsystem: String? = nil,
            category: String? = nil
        ) {
            self.date = date
            self.source = source
            self.text = text
            self.level = level
            self.subsystem = subsystem
            self.category = category
            self.timeText = DO.ConsoleLine.format(date)
        }

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter
        }()

        private static let formatterLock = NSLock()

        private static func format(_ date: Date) -> String {
            formatterLock.lock()
            defer { formatterLock.unlock() }
            return timeFormatter.string(from: date)
        }

        /// Xcode's metadata column, near enough: the source, plus the category for unified log lines.
        var metaTag: String {
            switch source {
            case .standardOutput: return source.shortTitle
            case .standardError:  return source.shortTitle
            case .unifiedLog:
                guard let category = category, !category.isEmpty else { return source.shortTitle }
                return source.shortTitle + " " + category
            }
        }

        /// What the list shows, and therefore what a tap puts on the pasteboard.
        var copyText: String {
            "\(timeText)  \(metaTag)  \(text)"
        }

        var metaText: String {
            var parts = [timeText]
            if let level = level { parts.append(level.title) }
            parts.append(source.title)
            return parts.joined(separator: " · ")
        }

        mutating func setText(_ newText: String, limit: Int) {
            let needsTruncating = newText.utf8.count > limit && newText.count > limit
            text = needsTruncating ? String(newText.prefix(limit)) : newText
        }

        mutating func appendContinuation(_ fragment: String, limit: Int) {
            setText(text + "\n" + fragment, limit: limit)
        }

    }
}
