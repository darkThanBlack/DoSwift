//
//  NetworkCaptureRecordTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest

@testable import DoSwiftKit

/// Answers every request with a fixed payload so the capture pipeline can be tested offline.
private final class StubProtocol: URLProtocol {

    static let body = Data(#"{"ok":true}"#.utf8)

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 201,
            httpVersion: "HTTP/1.1",
            headerFields: ["X-Stub": "1"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class RecordingDelegate: NSObject, URLSessionDataDelegate {

    var onFinish: (() -> Void)?

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onFinish?()
    }
}

final class NetworkCaptureRecordTests: XCTestCase {

    private func session(delegate: URLSessionDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        if let delegate = delegate {
            return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        }
        return URLSession(configuration: configuration)
    }

    override func setUp() {
        super.setUp()
        DO.NetworkCapture.shared.start()
        DO.NetworkCapture.shared.clear()
    }

    func testCompletionHandlerRequestIsCaptured() {
        let done = expectation(description: "request finished")

        let task = session().dataTask(with: URL(string: "https://example.test/hello")!) { _, _, _ in
            done.fulfill()
        }
        task.resume()
        wait(for: [done], timeout: 5)

        let records = DO.NetworkCapture.shared.snapshot()
        XCTAssertEqual(records.count, 1)

        let record = records.first
        XCTAssertEqual(record?.method, "GET")
        XCTAssertEqual(record?.url?.absoluteString, "https://example.test/hello")
        XCTAssertEqual(record?.status, 201)
        XCTAssertEqual(record?.responseHeaders["X-Stub"], "1")
        XCTAssertEqual(record?.responseBody?.text, #"{"ok":true}"#)
        XCTAssertFalse(record?.isFailed ?? true)
    }

    func testSessionDelegateRequestIsCaptured() {
        let delegate = RecordingDelegate()
        let done = expectation(description: "request finished")
        delegate.onFinish = { done.fulfill() }

        let session = session(delegate: delegate)
        session.dataTask(with: URL(string: "https://example.test/delegate")!).resume()
        wait(for: [done], timeout: 5)

        let records = DO.NetworkCapture.shared.snapshot()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.status, 201)
        XCTAssertEqual(records.first?.responseBody?.text, #"{"ok":true}"#)
    }

    func testUploadRequestBodyIsCaptured() {
        var request = URLRequest(url: URL(string: "https://example.test/upload")!)
        request.httpMethod = "POST"
        let body = Data(#"{"name":"x"}"#.utf8)

        let done = expectation(description: "request finished")
        session().uploadTask(with: request, from: body) { _, _, _ in done.fulfill() }.resume()
        wait(for: [done], timeout: 5)

        let record = DO.NetworkCapture.shared.snapshot().first
        XCTAssertEqual(record?.method, "POST")
        XCTAssertEqual(record?.requestBody?.text, #"{"name":"x"}"#)
        XCTAssertEqual(record?.status, 201)
    }

    func testBodyIsCapped() {
        let body = Data(repeating: 1, count: DO.NetworkBody.maxBytes + 10)
        let capped = DO.NetworkBody.capped(body)

        XCTAssertEqual(capped.byteCount, DO.NetworkBody.maxBytes)
        XCTAssertTrue(capped.truncated)
    }

    func testCaptureStopsWhenDisabled() {
        DO.NetworkCapture.shared.stop()

        let done = expectation(description: "request finished")
        let task = session().dataTask(with: URL(string: "https://example.test/ignored")!) { _, _, _ in
            done.fulfill()
        }
        task.resume()
        wait(for: [done], timeout: 5)

        XCTAssertTrue(DO.NetworkCapture.shared.snapshot().isEmpty)
        DO.NetworkCapture.shared.start()
    }

    func testBufferDropsOldestRecords() {
        DO.NetworkCapture.shared.clear()

        let limit = DO.NetworkCapture.capacity
        let done = expectation(description: "requests finished")
        done.expectedFulfillmentCount = limit + 2

        let session = session()
        for index in 0...(limit + 1) {
            let task = session.dataTask(with: URL(string: "https://example.test/\(index)")!) { _, _, _ in
                done.fulfill()
            }
            task.resume()
        }
        wait(for: [done], timeout: 20)

        let records = DO.NetworkCapture.shared.snapshot()
        XCTAssertEqual(records.count, limit)
        XCTAssertEqual(records.last?.url?.absoluteString, "https://example.test/\(limit + 1)")
        XCTAssertEqual(records.first?.url?.absoluteString, "https://example.test/2")
    }
}
