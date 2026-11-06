//
//  HierarchyConstraintTests.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/05
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import XCTest
import UIKit

@testable import DoSwiftKit

final class HierarchyConstraintTests: XCTestCase {

    private var engine: DO.HierarchyConstraintEngine { DO.HierarchyConstraintEngine.shared }

    private func summary(_ constraint: NSLayoutConstraint, in view: UIView) -> DO.HierarchyConstraintSummary {
        return engine.summary(for: constraint, from: view)
    }

    func testCenterSummary() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let child = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        parent.addSubview(child)

        let constraint = child.centerXAnchor.constraint(equalTo: parent.centerXAnchor)
        constraint.isActive = true

        let result = summary(constraint, in: child)
        XCTAssertEqual(result.left, "self.centerX")
        XCTAssertEqual(result.relation, "==")
        XCTAssertEqual(result.right, "superview.centerX")
        XCTAssertEqual(result.fullText, "self.centerX == superview.centerX")
    }

    func testWidthWithPriority() {
        let view = UIView()
        let constraint = view.widthAnchor.constraint(equalToConstant: 44)
        constraint.priority = UILayoutPriority(750)
        constraint.isActive = true

        XCTAssertEqual(summary(constraint, in: view).fullText, "self.width == 44 @750")
    }

    func testMultiplierConstantAndInactive() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)

        let constraint = child.widthAnchor.constraint(equalTo: parent.widthAnchor,
                                                      multiplier: 1.5,
                                                      constant: -8)
        XCTAssertEqual(summary(constraint, in: child).fullText,
                       "self.width == superview.width × 1.5 - 8 \(DO.Text.Hierarchy.constraintInactive)")
    }

    func testRolesFollowTheSelectedView() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)
        let grandchild = UIView()
        child.addSubview(grandchild)

        let selectedIsSecond = parent.leadingAnchor.constraint(equalTo: child.leadingAnchor)
        selectedIsSecond.isActive = true
        XCTAssertEqual(summary(selectedIsSecond, in: child).fullText,
                       "superview.leading == self.leading")

        let otherIsSubview = grandchild.leadingAnchor.constraint(equalTo: child.leadingAnchor)
        otherIsSubview.isActive = true
        XCTAssertEqual(summary(otherIsSubview, in: child).fullText,
                       "subview.UIView.leading == self.leading")
    }

    func testCollectionWalksTheAncestors() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)

        let width = child.widthAnchor.constraint(equalToConstant: 10)
        width.isActive = true
        let center = child.centerXAnchor.constraint(equalTo: parent.centerXAnchor)
        center.isActive = true

        let constraints = engine.constraints(involving: child)
        XCTAssertTrue(constraints.contains { $0 === width })
        XCTAssertTrue(constraints.contains { $0 === center })
    }

    func testEditConstantAndPriority() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)

        let constraint = child.widthAnchor.constraint(equalToConstant: 10)
        constraint.isActive = true

        engine.setConstant(20, on: constraint, in: child)
        engine.setPriority(UILayoutPriority(250), on: constraint, in: child)

        XCTAssertEqual(constraint.constant, 20)
        XCTAssertEqual(constraint.priority.rawValue, 250)
        XCTAssertTrue(constraint.isActive)
    }
}
