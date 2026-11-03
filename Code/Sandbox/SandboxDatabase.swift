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

    /// 只读 SQLite 查询。沿用 DoKit：看文件头 `SQLite format 3\0`，而不是只看后缀。
    enum SandboxDatabase {

        /// 单表一次最多读这么多行：大表整表读进内存会卡主线程，浏览用途取前若干行足够
        static let maxRows: Int = 500

        struct TableRows {

            let columns: [String]

            let rows: [[String?]]

            /// 是否因为 ``maxRows`` 截断了
            let truncated: Bool
        }

        /// 用文件头判断，而不是只看后缀
        static func isSQLiteFile(_ url: URL) -> Bool {
            guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
            defer { try? handle.close() }

            return handle.readData(ofLength: 16) == Data("SQLite format 3\u{0}".utf8)
        }

        /// 库里所有普通表（不含 sqlite_ 内部表 / 视图 / 索引）
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

        /// 单表内容（列名 + 行），最多 ``maxRows`` 行
        static func rows(at url: URL, table: String) -> TableRows? {
            guard let db = open(url) else { return nil }
            defer { sqlite3_close(db) }

            /// 表名来自 `sqlite_master`，仍按标识符规则转义，避免奇怪名字把语句带偏
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

        /// 一列 → 展示字符串；NULL 给 nil，BLOB 只报长度（二进制没法念）
        private static func string(_ statement: OpaquePointer, _ index: Int32) -> String? {
            switch sqlite3_column_type(statement, index) {
            case SQLITE_NULL:
                return nil

            case SQLITE_BLOB:
                return "<\(sqlite3_column_bytes(statement, index)) 字节的 BLOB>"

            default:
                guard let text = sqlite3_column_text(statement, index) else { return nil }
                return String(cString: text)
            }
        }
    }
}
