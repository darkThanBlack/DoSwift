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

    /// The only place in this library that touches the Objective-C runtime.
    ///
    /// Replacing an implementation is easy; keeping it correct is not. Three rules are baked in:
    ///
    /// 1. **The previous implementation is captured before the swap and handed back.** Swift
    ///    cannot go through `objc_msgSend`, so a hook that wants to forward has to hold that
    ///    `IMP` itself and invoke it through `cast(_:to:)`.
    /// 2. **Replacement goes through `class_replaceMethod`, never `method_exchangeImplementations`.**
    ///    When the method is inherited, exchange mutates the *superclass* and every sibling
    ///    subclass silently picks up the hook. Replace adds the method to the receiver instead,
    ///    which is exactly what "hook this class only" means.
    /// 3. **One swap per (class, selector, kind).** Calling again returns the implementation
    ///    captured the first time, so a second install cannot stack our own hook on itself.
    ///
    /// Everything runs on one serial queue. That only serializes callers inside this library;
    /// another framework replacing the same selector is outside anyone's control. Use
    /// `currentImplementation(of:_:isClassMethod:)` if you need to notice that it happened.
    enum Swizzler {

        private struct Key: Hashable {
            let target: ObjectIdentifier
            let selector: String
        }

        private static var originals: [Key: IMP] = [:]

        private static let queue = DispatchQueue(label: "com.doswift.swizzler")

        // MARK: - Replace

        /// Hooks an instance method.
        ///
        /// - Parameter block: a `@convention(block)` closure whose signature is the original
        ///   method's **without `_cmd`** — receiver first, then the arguments in order:
        ///
        ///   ```swift
        ///   // -[NSURLSession dataTaskWithRequest:]
        ///   let hook: @convention(block) (AnyObject, URLRequest) -> URLSessionDataTask = { object, request in ... }
        ///   ```
        ///
        ///   A mismatched signature does not fail to compile; it corrupts the stack at call time.
        ///   Declare the closure's type explicitly so the compiler checks it once.
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

        /// The implementation that would run right now for this class and selector.
        ///
        /// Compare it with the hook you installed to tell whether somebody replaced the method
        /// after you. Doing that on a timer is unnecessary; once when the tool opens is enough.
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

        /// Reinterprets an `IMP` as a callable function.
        ///
        /// The type must be the original method's signature **including `_cmd`**, because the
        /// runtime does not pass a selector to a block:
        ///
        /// ```swift
        /// typealias Original = @convention(c) (AnyObject, Selector, URLRequest) -> URLSessionDataTask
        /// let original = DO.Swizzler.cast(implementation, to: Original.self)
        /// ```
        ///
        /// `unsafeBitCast` is the only route: Swift forbids calling `objc_msgSend`.
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
