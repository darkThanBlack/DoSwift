//
//  NetworkTaskBox.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation
import ObjectiveC
import QuartzCore

extension DO {

    /// The mutable half of a capture: attached to a task while it runs, turned into a
    /// `NetworkRecord` once it finishes.
    ///
    /// `didReceiveData` and the completion handler can both report the same task on some
    /// paths, so finishing is guarded — the first caller wins, and the record is emitted once.
    final class NetworkTaskBox {

        private static var associationKey: UInt8 = 0

        let id: Int

        let start: TimeInterval

        let request: URLRequest?

        private(set) var requestBody: DO.NetworkBody?

        private let lock = NSLock()
        private var responseData = Data()
        private var truncated = false
        private var finished = false

        init(id: Int, request: URLRequest?) {
            self.id = id
            self.start = CACurrentMediaTime()
            self.request = request
            self.requestBody = request?.httpBody.map(DO.NetworkBody.capped)
        }

        func setRequestBody(_ data: Data) {
            requestBody = DO.NetworkBody.capped(data)
        }

        func append(_ data: Data) {
            lock.lock()
            defer { lock.unlock() }
            guard !finished else { return }

            let room = DO.NetworkBody.maxBytes - responseData.count
            guard room > 0 else {
                truncated = true
                return
            }
            if data.count > room {
                responseData.append(data.prefix(room))
                truncated = true
            } else {
                responseData.append(data)
            }
        }

        /// Freezes the box into a record. Returns nil when it was already finished.
        func finish(response: URLResponse?, error: Error?) -> DO.NetworkRecord? {
            lock.lock()
            defer { lock.unlock() }
            guard !finished else { return nil }
            finished = true

            let http = response as? HTTPURLResponse
            let headers = http?.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                guard let key = pair.key as? String else { return }
                result[key] = String(describing: pair.value)
            } ?? [:]

            return DO.NetworkRecord(
                id: id,
                start: start,
                method: request?.httpMethod ?? "GET",
                url: request?.url,
                requestHeaders: request?.allHTTPHeaderFields ?? [:],
                requestBody: requestBody,
                status: http?.statusCode,
                responseHeaders: headers,
                responseBody: responseData.isEmpty ? nil : DO.NetworkBody(data: responseData, truncated: truncated),
                end: CACurrentMediaTime(),
                error: error.map { String(describing: $0) }
            )
        }
    }
}

extension DO.NetworkTaskBox {

    static func attach(_ box: DO.NetworkTaskBox, to task: URLSessionTask) {
        objc_setAssociatedObject(task, &associationKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func box(for task: URLSessionTask) -> DO.NetworkTaskBox? {
        objc_getAssociatedObject(task, &associationKey) as? DO.NetworkTaskBox
    }
}
