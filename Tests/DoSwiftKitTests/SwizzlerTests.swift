//
//  SwizzlerTests.swift
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

private final class Greeter: NSObject {

    var trace: [String] = []

    @objc dynamic func greet(_ name: String) -> String {
        trace.append("original")
        return "hello \(name)"
    }
}

/// Each test needs its own fixture class: swizzling is process-wide and never undone.
private final class Repeatable: NSObject {
    @objc dynamic func greet(_ name: String) -> String { "real" }
}

private final class Inspected: NSObject {
    @objc dynamic func greet(_ name: String) -> String { "real" }
}

private class Base: NSObject {
    @objc dynamic func number() -> Int { 1 }
}

private final class Derived: Base {}

private final class Factory: NSObject {
    @objc dynamic class func make() -> String { "real" }
}

final class SwizzlerTests: XCTestCase {

    func testHookRunsAndForwards() {
        let selector = #selector(Greeter.greet(_:))
        var original: IMP?

        let hook: @convention(block) (AnyObject, String) -> String = { object, name in
            let greeter = object as! Greeter
            greeter.trace.append("hook")

            typealias Original = @convention(c) (AnyObject, Selector, String) -> String
            return DO.Swizzler.cast(original!, to: Original.self)(object, selector, name)
        }

        original = DO.Swizzler.replaceInstanceMethod(of: Greeter.self, selector, with: hook)

        XCTAssertNotNil(original)

        let greeter = Greeter()
        XCTAssertEqual(greeter.greet("you"), "hello you")
        XCTAssertEqual(greeter.trace, ["hook", "original"])
    }

    func testSecondInstallReturnsTheSameOriginal() {
        let selector = #selector(Repeatable.greet(_:))

        let first: @convention(block) (AnyObject, String) -> String = { _, _ in "first" }
        let second: @convention(block) (AnyObject, String) -> String = { _, _ in "second" }

        let original = DO.Swizzler.replaceInstanceMethod(of: Repeatable.self, selector, with: first)
        let again = DO.Swizzler.replaceInstanceMethod(of: Repeatable.self, selector, with: second)

        XCTAssertEqual(original, again)

        // The first hook is still the one installed; the second call was a no-op.
        XCTAssertEqual(Repeatable().greet("x"), "first")
    }

    func testHookingASubclassDoesNotTouchTheSuperclass() {
        let selector = #selector(Base.number)

        let hook: @convention(block) (AnyObject) -> Int = { _ in 42 }
        XCTAssertNotNil(DO.Swizzler.replaceInstanceMethod(of: Derived.self, selector, with: hook))

        XCTAssertEqual(Derived().number(), 42)
        XCTAssertEqual(Base().number(), 1, "the superclass keeps its own implementation")
    }

    func testClassMethod() {
        let selector = #selector(Factory.make)

        let hook: @convention(block) (AnyObject) -> String = { _ in "hooked" }
        XCTAssertNotNil(DO.Swizzler.replaceClassMethod(of: Factory.self, selector, with: hook))

        XCTAssertEqual(Factory.make(), "hooked")
    }

    func testCurrentImplementationReportsTheReplacement() {
        let selector = #selector(Inspected.greet(_:))

        let before = DO.Swizzler.currentImplementation(of: Inspected.self, selector)

        let hook: @convention(block) (AnyObject, String) -> String = { _, _ in "hooked" }
        DO.Swizzler.replaceInstanceMethod(of: Inspected.self, selector, with: hook)

        let after = DO.Swizzler.currentImplementation(of: Inspected.self, selector)

        XCTAssertNotEqual(before, after)
        XCTAssertEqual(Inspected().greet("x"), "hooked")
    }
}
