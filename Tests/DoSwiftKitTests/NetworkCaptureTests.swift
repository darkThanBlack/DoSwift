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

@testable import DoSwiftKit

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

    func testRegisteringTheSameClassTwiceKeepsOneEntry() {
        DO.NetworkCapture.shared.start()

        _ = URLSession(configuration: .ephemeral)
        _ = URLSession(configuration: .ephemeral)

        let classes = DO.NetworkCapture.shared.sessionClasses
        XCTAssertEqual(Set(classes).count, classes.count, "duplicates in \(classes)")
    }
}
