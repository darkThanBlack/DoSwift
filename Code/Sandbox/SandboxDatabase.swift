//
//  SandboxDatabase.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation
import SQLite3

extension DO {

    /// Read-only SQLite queries. Sniffs the `SQLite format 3\0` header, not the extension.
    enum SandboxDatabase {

        /// Row cap per table: whole large tables would block the main thread.
        static let maxRows: Int = 500

        struct TableRows {

            let columns: [String]

            let rows: [[String?]]

            /// Whether ``maxRows`` cut the result short.
            let truncated: Bool
        }

        /// Header check rather than extension.
        static func isSQLiteFile(_ url: URL) -> Bool {
            guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
            defer { try? handle.close() }

            return handle.readData(ofLength: 16) == Data("SQLite format 3\u{0}".utf8)
        }

        /// Ordinary tables only — no `sqlite_` internals, views or indexes.
        static func tables(at url: URL) -> [String] {
            guard let db = open(url) else { return [] }
            defer { sqlite3_close(db) }

            var names: [String] = []
            var statement: OpaquePointer?
            let sql: String = "select name from sqlite_master where type = 'table' order by name"

            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
                  let statement = statement else {
                return []
            }
            defer { sqlite3_finalize(statement) }

            while sqlite3_step(statement) == SQLITE_ROW {
                if let text = sqlite3_column_text(statement, 0) {
                    names.append(String(cString: text))
                }
            }
            return names
        }

        /// One table's columns and rows, up to ``maxRows``.
        static func rows(at url: URL, table: String) -> TableRows? {
            guard let db = open(url) else { return nil }
            defer { sqlite3_close(db) }

            /// Names come from `sqlite_master` but are still quoted as identifiers.
            let quoted: String = "\"" + table.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            let sql: String = "select * from \(quoted) limit \(maxRows + 1)"

            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
                  let statement = statement else {
                return nil
            }
            defer { sqlite3_finalize(statement) }

            let columnCount: Int32 = sqlite3_column_count(statement)
            var columns: [String] = []
            for index in 0..<columnCount {
                columns.append(String(cString: sqlite3_column_name(statement, index)))
            }

            var rows: [[String?]] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                var values: [String?] = []
                for index in 0..<columnCount {
                    values.append(string(statement, index))
                }
                rows.append(values)
            }

            let truncated: Bool = rows.count > maxRows
            if truncated {
                rows.removeLast(rows.count - maxRows)
            }

            return TableRows(columns: columns, rows: rows, truncated: truncated)
        }

        // MARK: - Private

        private static func open(_ url: URL) -> OpaquePointer? {
            var db: OpaquePointer?
            guard sqlite3_open(url.path, &db) == SQLITE_OK else {
                if let db = db {
                    sqlite3_close(db)
                }
                return nil
            }
            return db
        }

        /// One column as text; nil for NULL, length only for BLOB.
        private static func string(_ statement: OpaquePointer, _ index: Int32) -> String? {
            switch sqlite3_column_type(statement, index) {
            case SQLITE_NULL:
                return nil

            case SQLITE_BLOB:
                return DO.Text.Sandbox.blobPlaceholder(sqlite3_column_bytes(statement, index))

            default:
                guard let text = sqlite3_column_text(statement, index) else { return nil }
                return String(cString: text)
            }
        }
    }
}
