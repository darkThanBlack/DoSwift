//
//  NetworkRecord.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// A payload kept for the detail page. Capped at capture time, so `truncated` says so out loud.
    struct NetworkBody {

        static let maxBytes = 64 * 1024

        let data: Data

        let truncated: Bool

        var byteCount: Int { data.count }

        var text: String? { String(data: data, encoding: .utf8) }

        static func capped(_ data: Data) -> DO.NetworkBody {
            guard data.count > maxBytes else {
                return DO.NetworkBody(data: data, truncated: false)
            }
            return DO.NetworkBody(data: data.prefix(maxBytes), truncated: true)
        }
    }

    /// One finished request. Immutable; anything still moving lives in `DO.NetworkTaskBox`.
    struct NetworkRecord {

        let id: Int

        let start: TimeInterval

        let method: String

        let url: URL?

        let requestHeaders: [String: String]

        let requestBody: DO.NetworkBody?

        let status: Int?

        let responseHeaders: [String: String]

        let responseBody: DO.NetworkBody?

        let end: TimeInterval?

        let error: String?

        var duration: TimeInterval? { end.map { $0 - start } }

        var isFailed: Bool { error != nil || (status ?? 0) >= 400 }
    }
}
