//
//  DoSwiftTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest

@testable import DoSwift

/// Placeholder suite that keeps the target alive: the network capture tests, and the swizzler
/// tests ported from Firebase, will land here.
final class DoSwiftTests: XCTestCase {

    func testCoreIsSingleton() {
        XCTAssertTrue(DO.Core.shared === DO.Core.shared)
    }
}
