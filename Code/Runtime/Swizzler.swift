//
//  Swizzler.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation
import ObjectiveC

extension DO {

    /// Hooks Objective-C methods with `class_replaceMethod` (never exchange: that rewrites the
    /// superclass and every sibling picks up the hook). The previous IMP is captured and handed
    /// back, since Swift cannot call `objc_msgSend`. One swap per (class, selector, kind), so a
    /// repeat install cannot stack our hook on itself.
    enum Swizzler {

        private struct Key: Hashable {
            let target: ObjectIdentifier
            let selector: String
        }

        private static var originals: [Key: IMP] = [:]

        private static let queue = DispatchQueue(label: "com.doswift.swizzler")

        // MARK: - Replace

        /// `block` has the original signature **without `_cmd`** — receiver, then arguments. A
        /// mismatch does not fail to compile; it corrupts the stack at call time.
        ///
        /// - Returns: the implementation that was in place before the swap.
        @discardableResult
        static func replaceInstanceMethod(
            of cls: AnyClass,
            _ selector: Selector,
            with block: Any
        ) -> IMP? {
            replace(of: cls, selector, isClassMethod: false, with: block)
        }

        /// Hooks a class method. Class methods live on the metaclass, which is resolved here.
        @discardableResult
        static func replaceClassMethod(
            of cls: AnyClass,
            _ selector: Selector,
            with block: Any
        ) -> IMP? {
            replace(of: cls, selector, isClassMethod: true, with: block)
        }

        // MARK: - Inspect

        /// The IMP that would run right now — compare it with our own hook to notice a later
        /// replacement. Once when the tool opens is enough; no need for a timer.
        static func currentImplementation(
            of cls: AnyClass,
            _ selector: Selector,
            isClassMethod: Bool = false
        ) -> IMP? {
            let method = isClassMethod
                ? class_getClassMethod(cls, selector)
                : class_getInstanceMethod(cls, selector)
            return method.map(method_getImplementation)
        }

        /// The type is the original signature **including `_cmd`** — the runtime passes a selector
        /// to an IMP but not to a block. `unsafeBitCast` is the only route; Swift has no `objc_msgSend`.
        @inline(__always)
        static func cast<F>(_ implementation: IMP, to type: F.Type) -> F {
            unsafeBitCast(implementation, to: F.self)
        }

        // MARK: - Private

        private static func replace(
            of cls: AnyClass,
            _ selector: Selector,
            isClassMethod: Bool,
            with block: Any
        ) -> IMP? {
            queue.sync {
                let target: AnyClass? = isClassMethod ? object_getClass(cls) : cls
                let method = isClassMethod
                    ? class_getClassMethod(cls, selector)
                    : class_getInstanceMethod(cls, selector)

                guard let target = target, let method = method else {
                    assertionFailure(
                        "DO.Swizzler: \(NSStringFromClass(cls)) does not respond to \(NSStringFromSelector(selector))"
                    )
                    return nil
                }

                let key = Key(target: ObjectIdentifier(target), selector: NSStringFromSelector(selector))
                if let captured = originals[key] { return captured }

                let original = method_getImplementation(method)
                let replacement = imp_implementationWithBlock(block)
                class_replaceMethod(target, selector, replacement, method_getTypeEncoding(method))

                originals[key] = original
                return original
            }
        }
    }
}
