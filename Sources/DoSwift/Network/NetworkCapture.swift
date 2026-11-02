//
//  NetworkCapture.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// Entry point for the network panel.
    ///
    /// `NSURLSession` is a class cluster: the class you get back from a factory method is a
    /// private subclass, and instance methods have to be hooked on *that* class. So the work
    /// happens in two stages:
    ///
    /// 1. Hook the three factory methods. Every session that flows through them is inspected
    ///    and its concrete class registered.
    /// 2. Registering a class is where the task level hooks will live. For now it only records
    ///    the name, which is enough to answer "did we catch the right class?" on a device.
    ///
    /// The hooks stay installed once `start()` runs; `stop()` only closes the gate, so nothing
    /// is ever un-swizzled out from under another framework.
    final class NetworkCapture {

        static let shared = DO.NetworkCapture()

        private init() {}

        // MARK: - State

        /// Whether captured traffic is recorded. Hooks keep running either way.
        private(set) var isEnabled = false

        /// Concrete session classes seen so far, in registration order. Debug aid.
        private(set) var sessionClasses: [String] = []

        private let lock = NSLock()
        private var seenClasses: Set<ObjectIdentifier> = []
        private var installed = false

        // MARK: - Public

        func start() {
            isEnabled = true
            installSessionHooks()
            warmUp()
        }

        func stop() {
            isEnabled = false
        }

        /// Clears recorded state. Test support only — the hooks themselves stay installed.
        func resetForTesting() {
            lock.lock()
            defer { lock.unlock() }
            seenClasses.removeAll()
            sessionClasses.removeAll()
            installed = false
        }

        /// Records a concrete session class. Called from the factory hooks.
        func register(_ sessionClass: AnyClass) {
            guard isEnabled else { return }

            let identifier = ObjectIdentifier(sessionClass)
            lock.lock()
            defer { lock.unlock() }

            guard seenClasses.insert(identifier).inserted else { return }
            sessionClasses.append(NSStringFromClass(sessionClass))
        }

        // MARK: - Hooks

        /// Calls the factories once, for their side effect only.
        ///
        /// Without this, a host that built every session before `start()` ran would never
        /// see a factory call again, the concrete class would stay unregistered, and the task
        /// level hooks would never be installed. Requests made from those sessions would be
        /// invisible even though they happen after `start()`.
        ///
        /// The sessions created here have no delegate and no tasks; they are released at once.
        private func warmUp() {
            _ = URLSession.shared
            _ = URLSession(configuration: .ephemeral)
        }

        private func installSessionHooks() {
            lock.lock()
            let alreadyInstalled = installed
            installed = true
            lock.unlock()
            guard !alreadyInstalled else { return }

            hookSharedSession()
            hookSessionWithConfiguration()
            hookSessionWithConfigurationDelegateDelegateQueue()
        }

        private func hookSharedSession() {
            let selector = NSSelectorFromString("sharedSession")
            var original: IMP?

            let hook: @convention(block) (AnyObject) -> URLSession = { object in
                typealias Original = @convention(c) (AnyObject, Selector) -> URLSession
                let session = DO.Swizzler.cast(original!, to: Original.self)(object, selector)
                DO.NetworkCapture.shared.register(type(of: session))
                return session
            }

            original = DO.Swizzler.replaceClassMethod(of: URLSession.self, selector, with: hook)
        }

        private func hookSessionWithConfiguration() {
            let selector = NSSelectorFromString("sessionWithConfiguration:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLSessionConfiguration) -> URLSession = { object, configuration in
                typealias Original = @convention(c) (AnyObject, Selector, URLSessionConfiguration) -> URLSession
                let session = DO.Swizzler.cast(original!, to: Original.self)(object, selector, configuration)
                DO.NetworkCapture.shared.register(type(of: session))
                return session
            }

            original = DO.Swizzler.replaceClassMethod(of: URLSession.self, selector, with: hook)
        }

        private func hookSessionWithConfigurationDelegateDelegateQueue() {
            let selector = NSSelectorFromString("sessionWithConfiguration:delegate:delegateQueue:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession = { object, configuration, delegate, queue in
                typealias Original = @convention(c) (AnyObject, Selector, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession
                let session = DO.Swizzler.cast(original!, to: Original.self)(object, selector, configuration, delegate, queue)
                DO.NetworkCapture.shared.register(type(of: session))
                return session
            }

            original = DO.Swizzler.replaceClassMethod(of: URLSession.self, selector, with: hook)
        }
    }
}
