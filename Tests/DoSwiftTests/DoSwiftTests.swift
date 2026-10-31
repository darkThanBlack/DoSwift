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

/// Placeholder suite, kept so the target stays alive.
///
/// The original skeleton tests asserted APIs that were never built — `isEnabled`,
/// `hasSubMenu`, `addSubMenuItem`, `DoSwiftWindow` — and stopped compiling long ago.
/// They are dropped rather than repaired: a menu item is a title plus an action, and there
/// is no sub-menu to test.
///
/// The target itself is worth keeping. The network capture work starts with a swizzler, and
/// Firebase ships a usable set of swizzler tests we intend to port alongside it. They need a
/// home, and this is it.
final class DoSwiftTests: XCTestCase {

    func testCoreIsSingleton() {
        XCTAssertTrue(DO.Core.shared === DO.Core.shared)
    }
}
