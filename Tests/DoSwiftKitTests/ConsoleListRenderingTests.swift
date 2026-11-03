//
//  ConsoleListRenderingTests.swift
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

final class ConsoleListRenderingTests: XCTestCase {

    private static func labels(in view: UIView) -> [UILabel] {
        return view.subviews.flatMap { subview -> [UILabel] in
            var result = labels(in: subview)
            if let label = subview as? UILabel { result.append(label) }
            return result
        }
    }

    func testRowsAreRendered() {
        let store = DO.ConsoleStore.shared
        store.clear()
        store.append(DO.ConsoleLine(date: Date(), source: .standardOutput, text: "hello from fd1"))
        store.append(DO.ConsoleLine(date: Date(), source: .standardError, text: "oops from fd2"))

        let controller = DO.ConsoleViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()

        let table = controller.view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(table, "no table view in the hierarchy")
        XCTAssertEqual(table?.numberOfRows(inSection: 0), 2)
        XCTAssertGreaterThan(table?.contentSize.height ?? 0, 0)

        // Newest first.
        let rendered = (0..<2).compactMap { row -> String? in
            guard let cell = table?.cellForRow(at: IndexPath(row: row, section: 0)) else { return nil }
            XCTAssertGreaterThan(cell.bounds.height, 0)
            return Self.labels(in: cell.contentView).compactMap(\.text).joined(separator: " | ")
        }
        XCTAssertEqual(rendered.count, 2)
        XCTAssertTrue(rendered.contains { $0.contains("fd1") && $0.contains("hello from fd1") }, "\(rendered)")
        XCTAssertTrue(rendered.contains { $0.contains("fd2") && $0.contains("oops from fd2") }, "\(rendered)")
    }

    func testTableHasHeightInsideNavigationController() {
        let controller = DO.ConsoleViewController()
        let nav = UINavigationController(rootViewController: controller)
        nav.setToolbarHidden(false, animated: false)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        nav.view.layoutIfNeeded()

        let table = controller.view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(table)
        XCTAssertGreaterThan(table?.bounds.height ?? 0, 100, "table collapsed inside a navigation controller")
    }
}

final class ConsoleStoreCountTests: XCTestCase {

    func testCountsFollowEachSource() {
        let store = DO.ConsoleStore.shared
        store.clear()

        let date = Date()
        store.append(DO.ConsoleLine(date: date, source: .standardOutput, text: "a"))
        store.append(DO.ConsoleLine(date: date, source: .standardOutput, text: "b"))
        store.append(DO.ConsoleLine(date: date, source: .standardError, text: "c"))

        XCTAssertEqual(store.capturedCount, 3)
        XCTAssertEqual(store.capturedCount(of: .standardOutput), 2)
        XCTAssertEqual(store.capturedCount(of: .standardError), 1)
        XCTAssertEqual(store.capturedCount(of: .unifiedLog), 0)
    }
}

final class ConsoleMergeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DO.ConsoleStore.shared.mergesSameTimestamp = []
        DO.ConsoleStore.shared.clear()
    }

    func testTogglingMergeAppliesToExistingLines() {
        let store = DO.ConsoleStore.shared

        let date = Date()
        for index in 0..<3 {
            store.append(DO.ConsoleLine(date: date, source: .standardError, text: "line \(index)"))
        }

        XCTAssertEqual(store.visibleLines().count, 3, "off by default in this test")

        store.mergesSameTimestamp = [.standardError]
        XCTAssertEqual(store.visibleLines().count, 1, "turning it on must regroup what is already here")
        XCTAssertEqual(store.visibleLines().first?.text, "line 0\nline 1\nline 2")

        store.mergesSameTimestamp = []
        XCTAssertEqual(store.visibleLines().count, 3, "turning it off must split them again")
    }

    func testDifferentTimestampsDoNotMerge() {
        let store = DO.ConsoleStore.shared
        store.mergesSameTimestamp = [.standardError]

        let start = Date()
        for index in 0..<3 {
            store.append(DO.ConsoleLine(
                date: start.addingTimeInterval(Double(index) * 0.01),
                source: .standardError,
                text: "line \(index)"
            ))
        }

        XCTAssertEqual(store.visibleLines().count, 3)
    }

    func testDifferentSourcesDoNotMerge() {
        let store = DO.ConsoleStore.shared
        store.mergesSameTimestamp = [.standardOutput, .standardError]

        let date = Date()
        store.append(DO.ConsoleLine(date: date, source: .standardOutput, text: "out"))
        store.append(DO.ConsoleLine(date: date, source: .standardError, text: "err"))

        XCTAssertEqual(store.visibleLines().count, 2)
    }
}
