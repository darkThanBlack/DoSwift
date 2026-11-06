//
//  HierarchyPropertyGroupTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/06
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyPropertyGroupTests: XCTestCase {

    func testStackGroupShowsEnumNamesAndIsEditable() {
        let stack = UIStackView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: stack)

        let stackSection = models.first { $0.title == "Stack" }
        XCTAssertNotNil(stackSection)

        let axis = stackSection?.items.first { $0.title == "axis" }
        XCTAssertEqual(axis?.detailTitle, "horizontal")
        XCTAssertNotNil(axis?.edit)

        let distribution = stackSection?.items.first { $0.title == "distribution" }
        XCTAssertEqual(distribution?.detailTitle, "fill")
        XCTAssertNotNil(distribution?.edit)
    }

    func testTranslatesAutoresizingMaskIsExposed() {
        let view = UIView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)
        let row = models.flatMap(\.items)
            .first { $0.title == "translatesAutoresizingMaskIntoConstraints" }

        XCTAssertEqual(row?.detailTitle, "true")
        XCTAssertNotNil(row?.edit)
    }

    func testNonStackViewHasNoStackGroup() {
        let view = UIView()
        let models = DO.HierarchyPropertyEngine.shared.categoryModels(for: view)
        XCTAssertFalse(models.contains { $0.title == "Stack" })
    }
}
