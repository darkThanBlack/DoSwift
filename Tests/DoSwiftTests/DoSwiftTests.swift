//
//  DoSwiftTests.swift
//  DoSwiftTests
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import XCTest
@testable import DoSwift

final class DoSwiftTests: XCTestCase {

    override func setUpWithError() throws {
        // 每个测试前的设置代码
    }

    override func tearDownWithError() throws {
        // 每个测试后的清理代码
    }

    func testDoSwiftCoreInitialization() throws {
        let core = DoSwiftCore.shared
        XCTAssertNotNil(core)
    }

    func testMenuItemCreation() throws {
        let menuItem = DoSwiftMenuItem(
            identifier: "test",
            title: "Test Item",
            icon: nil
        ) { _ in
            // 测试动作
        }

        XCTAssertEqual(menuItem.identifier, "test")
        XCTAssertEqual(menuItem.title, "Test Item")
        XCTAssertTrue(menuItem.isEnabled)
        XCTAssertFalse(menuItem.hasSubMenu)
    }

    func testMenuItemSubItems() throws {
        let parentItem = DoSwiftMenuItem(
            identifier: "parent",
            title: "Parent Item"
        )

        let childItem = DoSwiftMenuItem(
            identifier: "child",
            title: "Child Item"
        )

        parentItem.addSubMenuItem(childItem)

        XCTAssertTrue(parentItem.hasSubMenu)
        XCTAssertEqual(parentItem.subMenuItems.count, 1)
        XCTAssertEqual(parentItem.subMenuItems.first?.identifier, "child")
    }

    func testDoSwiftCoreSingleton() throws {
        let core1 = DoSwiftCore.shared
        let core2 = DoSwiftCore.shared

        XCTAssertTrue(core1 === core2)
    }

    func testDoSwiftWindowCreation() throws {
        let window = DoSwiftWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertNotNil(window)
        XCTAssertEqual(window.backgroundColor, UIColor.clear)
    }
}