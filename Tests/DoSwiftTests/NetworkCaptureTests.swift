//
//  NetworkCaptureTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest

@testable import DoSwift

final class NetworkCaptureTests: XCTestCase {

    func testSessionWithConfigurationRegistersConcreteClass() {
        DO.NetworkCapture.shared.start()

        let session = URLSession(configuration: .ephemeral)
        let name = NSStringFromClass(type(of: session))

        XCTAssertTrue(
            DO.NetworkCapture.shared.sessionClasses.contains(name),
            "expected \(name) in \(DO.NetworkCapture.shared.sessionClasses)"
        )
    }

    func testSessionWithDelegateRegistersConcreteClass() {
        DO.NetworkCapture.shared.start()

        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: nil)
        let name = NSStringFromClass(type(of: session))

        XCTAssertTrue(DO.NetworkCapture.shared.sessionClasses.contains(name))
    }

    func testSharedSessionRegistersConcreteClass() {
        DO.NetworkCapture.shared.start()

        let session = URLSession.shared
        let name = NSStringFromClass(type(of: session))

        XCTAssertTrue(DO.NetworkCapture.shared.sessionClasses.contains(name))
    }

    func testStartRegistersEvenWhenNoSessionIsCreatedAfterwards() {
        DO.NetworkCapture.shared.resetForTesting()
        DO.NetworkCapture.shared.stop()

        // Simulates a host that built every session before the tool existed: the hooks are
        // in place, but the gate is closed, so nothing is recorded.
        _ = URLSession(configuration: .ephemeral)
        XCTAssertTrue(DO.NetworkCapture.shared.sessionClasses.isEmpty, "hooks are not installed yet")

        DO.NetworkCapture.shared.start()

        XCTAssertFalse(
            DO.NetworkCapture.shared.sessionClasses.isEmpty,
            "warm-up should have discovered the concrete class"
        )
    }

    func testRegisteringTheSameClassTwiceKeepsOneEntry() {
        DO.NetworkCapture.shared.start()

        _ = URLSession(configuration: .ephemeral)
        _ = URLSession(configuration: .ephemeral)

        let classes = DO.NetworkCapture.shared.sessionClasses
        XCTAssertEqual(Set(classes).count, classes.count, "duplicates in \(classes)")
    }
}
