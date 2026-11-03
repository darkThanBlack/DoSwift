//
//  ConsoleSettingsTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/03
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest

@testable import DoSwiftKit

final class ConsoleSettingsTests: XCTestCase {

    /// `load()` is global state, so every test puts back what it found.
    private var original: DO.ConsoleSettings!

    override func setUp() {
        super.setUp()
        original = DO.ConsoleSettings.load()
    }

    override func tearDown() {
        original.save()
        super.tearDown()
    }

    func testDefaults() {
        let settings = DO.ConsoleSettings()

        XCTAssertEqual(settings.sources, Set(DO.ConsoleLine.Source.allCases))
        XCTAssertEqual(settings.mergesSameTimestamp, [.standardOutput, .standardError])
        XCTAssertTrue(settings.includesEmptySubsystem)
    }

    func testRoundTrip() {
        let settings = DO.ConsoleSettings(
            sources: [.unifiedLog],
            mergesSameTimestamp: [.standardOutput, .unifiedLog],
            includesEmptySubsystem: false
        )
        settings.save()

        XCTAssertEqual(DO.ConsoleSettings.load(), settings)
    }

    /// A key added later must not wipe the keys that are already stored.
    func testMissingKeysFallBackToDefaults() throws {
        let data = try JSONEncoder().encode(["sources": ["standardError"]])
        let settings = try JSONDecoder().decode(DO.ConsoleSettings.self, from: data)

        XCTAssertEqual(settings.sources, [.standardError])
        XCTAssertEqual(settings.mergesSameTimestamp, [.standardOutput, .standardError])
        XCTAssertTrue(settings.includesEmptySubsystem)
    }
}
