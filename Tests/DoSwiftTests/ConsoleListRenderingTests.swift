import XCTest

@testable import DoSwift

final class ConsoleListRenderingTests: XCTestCase {

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
        let texts = (0..<2).compactMap { row -> String? in
            guard let cell = table?.cellForRow(at: IndexPath(row: row, section: 0)) else { return nil }
            XCTAssertGreaterThan(cell.bounds.height, 0)
            let label = cell.contentView.subviews.compactMap { $0 as? UILabel }.first
            return label?.attributedText?.string
        }
        XCTAssertEqual(texts.count, 2)
        XCTAssertTrue(texts.contains { $0.contains("fd1") && $0.contains("hello from fd1") }, "\(texts)")
        XCTAssertTrue(texts.contains { $0.contains("fd2") && $0.contains("oops from fd2") }, "\(texts)")
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

final class ConsoleMergeTests: XCTestCase {

    func testSameTimestampMerges() {
        let store = DO.ConsoleStore.shared
        store.clear()

        let date = Date()
        for index in 0..<3 {
            store.append(DO.ConsoleLine(date: date, source: .standardOutput, text: "line \(index)"))
        }

        XCTAssertEqual(store.visibleLines().count, 1)
        XCTAssertEqual(store.visibleLines().first?.text, "line 0\nline 1\nline 2")
    }

    func testDifferentTimestampsDoNotMerge() {
        let store = DO.ConsoleStore.shared
        store.clear()

        let start = Date()
        for index in 0..<3 {
            store.append(DO.ConsoleLine(
                date: start.addingTimeInterval(Double(index) * 0.01),
                source: .standardOutput,
                text: "line \(index)"
            ))
        }

        XCTAssertEqual(store.visibleLines().count, 3)
    }

    func testDifferentSourcesDoNotMerge() {
        let store = DO.ConsoleStore.shared
        store.clear()

        let date = Date()
        store.append(DO.ConsoleLine(date: date, source: .standardOutput, text: "out"))
        store.append(DO.ConsoleLine(date: date, source: .standardError, text: "err"))

        XCTAssertEqual(store.visibleLines().count, 2)
    }
}
