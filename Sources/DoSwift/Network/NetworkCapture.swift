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
import ObjectiveC
import QuartzCore

extension DO {

    /// Captures HTTP traffic made through `URLSession`.
    ///
    /// `NSURLSession` is a class cluster: the class you get back from a factory method is a
    /// private subclass (`__NSURLSessionLocal` on current iOS), and instance methods have to
    /// be hooked on *that* class. So the work happens in two stages:
    ///
    /// 1. Hook the three factory methods. Every session that flows through them is inspected,
    ///    its concrete class registered, and its delegate — if any — hooked as well.
    /// 2. The first time a concrete class is seen, install the four task-creation hooks on it.
    ///
    /// Nothing is ever un-swizzled. `stop()` only closes the gate, so a second framework that
    /// stacked a hook on top of ours keeps working. `start()` must be called by the host; the
    /// library never swizzles on its own.
    ///
    /// Consequence worth knowing: instrumentation is discovered, not enforced. A session
    /// created *before* `start()` was never seen by a factory hook, so its concrete class is
    /// unknown and its tasks are invisible — until some other session is created after
    /// `start()`, which registers the shared class and retroactively covers the old one. Call
    /// `start()` early; every request made afterwards is captured.
    ///
    /// Not covered: `WKWebView`, `URLSessionWebSocketTask`, uploads whose body is an
    /// `InputStream`, and any traffic that does not go through `URLSession`.
    final class NetworkCapture {

        static let shared = DO.NetworkCapture()

        /// Oldest records are dropped beyond this.
        static let capacity = 200

        private typealias DataCompletion = @convention(block) (Data?, URLResponse?, Error?) -> Void

        private init() {}

        // MARK: - State

        /// Whether traffic is recorded. Hooks keep running either way.
        private(set) var isEnabled = false

        /// Concrete session classes seen so far, in registration order. Debug aid.
        private(set) var sessionClasses: [String] = []

        /// Stands in for sessions created with `delegate: nil`.
        let injectedDelegate = DO.NetworkSessionDelegate()

        private let lock = NSLock()
        private var seenSessionClasses: Set<ObjectIdentifier> = []
        private var seenDelegateClasses: Set<ObjectIdentifier> = []
        private var installed = false
        private var nextID = 0
        private var records: [DO.NetworkRecord] = []

        // MARK: - Public

        func start() {
            isEnabled = true
            installSessionHooks()
        }

        func stop() {
            isEnabled = false
        }

        func snapshot() -> [DO.NetworkRecord] {
            lock.lock()
            defer { lock.unlock() }
            return records
        }

        func clear() {
            lock.lock()
            defer { lock.unlock() }
            records.removeAll()
        }

        /// Clears recorded state. Test support only — the hooks themselves stay installed.
        func resetForTesting() {
            lock.lock()
            defer { lock.unlock() }
            seenSessionClasses.removeAll()
            seenDelegateClasses.removeAll()
            sessionClasses.removeAll()
            records.removeAll()
            installed = false
        }

        // MARK: - Recording

        func begin(request: URLRequest?) -> DO.NetworkTaskBox? {
            guard isEnabled else { return nil }

            lock.lock()
            nextID += 1
            let id = nextID
            lock.unlock()

            return DO.NetworkTaskBox(id: id, request: request)
        }

        func attach(to task: URLSessionTask, request: URLRequest?) {
            guard let box = begin(request: request ?? task.originalRequest) else { return }
            DO.NetworkTaskBox.attach(box, to: task)
        }

        func commit(_ box: DO.NetworkTaskBox, response: URLResponse?, error: Error?) {
            guard isEnabled, let record = box.finish(response: response, error: error) else { return }

            lock.lock()
            defer { lock.unlock() }
            records.append(record)
            if records.count > Self.capacity {
                records.removeFirst(records.count - Self.capacity)
            }
        }

        // MARK: - Session hooks

        /// Records a concrete session class and instruments it the first time it shows up.
        func register(_ sessionClass: AnyClass) {
            guard isEnabled else { return }

            lock.lock()
            let isNew = seenSessionClasses.insert(ObjectIdentifier(sessionClass)).inserted
            if isNew { sessionClasses.append(NSStringFromClass(sessionClass)) }
            lock.unlock()

            guard isNew else { return }
            instrument(sessionClass)
        }

        /// Hooks a delegate the app supplied itself.
        func instrument(delegate: URLSessionDelegate) {
            guard isEnabled else { return }

            let cls: AnyClass = type(of: delegate)
            lock.lock()
            let isNew = seenDelegateClasses.insert(ObjectIdentifier(cls)).inserted
            lock.unlock()

            guard isNew else { return }
            hookDidReceiveData(cls)
            hookDidCompleteWithError(cls)
        }

        private func instrument(_ cls: AnyClass) {
            hookDataTaskWithURL(cls)
            hookDataTaskWithURLCompletion(cls)
            hookDataTaskWithRequest(cls)
            hookDataTaskWithCompletion(cls)
            hookUploadWithData(cls)
            hookUploadWithDataCompletion(cls)
            hookUploadWithFile(cls)
            hookUploadWithFileCompletion(cls)
        }

        private func installSessionHooks() {
            lock.lock()
            let alreadyInstalled = installed
            installed = true
            lock.unlock()
            guard !alreadyInstalled else { return }

            hookSharedSession()
            hookSessionWithConfiguration()
            hookSessionWithDelegate()
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

        private func hookSessionWithDelegate() {
            let selector = NSSelectorFromString("sessionWithConfiguration:delegate:delegateQueue:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession = { object, configuration, delegate, queue in
                typealias Original = @convention(c) (AnyObject, Selector, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession

                var effective = delegate
                if let delegate = delegate {
                    DO.NetworkCapture.shared.instrument(delegate: delegate)
                } else {
                    effective = DO.NetworkCapture.shared.injectedDelegate
                }

                let session = DO.Swizzler.cast(original!, to: Original.self)(object, selector, configuration, effective, queue)
                DO.NetworkCapture.shared.register(type(of: session))
                return session
            }

            original = DO.Swizzler.replaceClassMethod(of: URLSession.self, selector, with: hook)
        }

        // MARK: - Task hooks

        private func hookDataTaskWithURL(_ cls: AnyClass) {
            let selector = NSSelectorFromString("dataTaskWithURL:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URL) -> URLSessionDataTask = { object, url in
                typealias Original = @convention(c) (AnyObject, Selector, URL) -> URLSessionDataTask
                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, url)
                DO.NetworkCapture.shared.attach(to: task, request: task.originalRequest)
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookDataTaskWithURLCompletion(_ cls: AnyClass) {
            let selector = NSSelectorFromString("dataTaskWithURL:completionHandler:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URL, DataCompletion?) -> URLSessionDataTask = { object, url, completion in
                typealias Original = @convention(c) (AnyObject, Selector, URL, DataCompletion?) -> URLSessionDataTask

                var box: DO.NetworkTaskBox?
                let wrapped = completion.map { handler -> DataCompletion in
                    return { data, response, error in
                        if let box = box {
                            if let data = data { box.append(data) }
                            DO.NetworkCapture.shared.commit(box, response: response, error: error)
                        }
                        handler(data, response, error)
                    }
                }

                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, url, wrapped)
                box = DO.NetworkCapture.shared.begin(request: task.originalRequest)
                if let box = box { DO.NetworkTaskBox.attach(box, to: task) }
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookDataTaskWithRequest(_ cls: AnyClass) {
            let selector = NSSelectorFromString("dataTaskWithRequest:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest) -> URLSessionDataTask = { object, request in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest) -> URLSessionDataTask
                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request)
                DO.NetworkCapture.shared.attach(to: task, request: task.originalRequest ?? request)
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookDataTaskWithCompletion(_ cls: AnyClass) {
            let selector = NSSelectorFromString("dataTaskWithRequest:completionHandler:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest, DataCompletion?) -> URLSessionDataTask = { object, request, completion in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest, DataCompletion?) -> URLSessionDataTask

                var box: DO.NetworkTaskBox?
                let wrapped = completion.map { handler -> DataCompletion in
                    return { data, response, error in
                        if let box = box {
                            if let data = data { box.append(data) }
                            DO.NetworkCapture.shared.commit(box, response: response, error: error)
                        }
                        handler(data, response, error)
                    }
                }

                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request, wrapped)
                box = DO.NetworkCapture.shared.begin(request: task.originalRequest ?? request)
                if let box = box { DO.NetworkTaskBox.attach(box, to: task) }
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookUploadWithData(_ cls: AnyClass) {
            let selector = NSSelectorFromString("uploadTaskWithRequest:fromData:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest, Data) -> URLSessionUploadTask = { object, request, data in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest, Data) -> URLSessionUploadTask
                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request, data)
                DO.NetworkCapture.shared.attach(to: task, request: task.originalRequest ?? request)
                DO.NetworkTaskBox.box(for: task)?.setRequestBody(data)
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookUploadWithDataCompletion(_ cls: AnyClass) {
            let selector = NSSelectorFromString("uploadTaskWithRequest:fromData:completionHandler:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest, Data, DataCompletion?) -> URLSessionUploadTask = { object, request, data, completion in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest, Data, DataCompletion?) -> URLSessionUploadTask

                var box: DO.NetworkTaskBox?
                let wrapped = completion.map { handler -> DataCompletion in
                    return { received, response, error in
                        if let box = box {
                            if let received = received { box.append(received) }
                            DO.NetworkCapture.shared.commit(box, response: response, error: error)
                        }
                        handler(received, response, error)
                    }
                }

                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request, data, wrapped)
                box = DO.NetworkCapture.shared.begin(request: task.originalRequest ?? request)
                box?.setRequestBody(data)
                if let box = box { DO.NetworkTaskBox.attach(box, to: task) }
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookUploadWithFileCompletion(_ cls: AnyClass) {
            let selector = NSSelectorFromString("uploadTaskWithRequest:fromFile:completionHandler:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest, URL, DataCompletion?) -> URLSessionUploadTask = { object, request, url, completion in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest, URL, DataCompletion?) -> URLSessionUploadTask

                var box: DO.NetworkTaskBox?
                let wrapped = completion.map { handler -> DataCompletion in
                    return { received, response, error in
                        if let box = box {
                            if let received = received { box.append(received) }
                            DO.NetworkCapture.shared.commit(box, response: response, error: error)
                        }
                        handler(received, response, error)
                    }
                }

                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request, url, wrapped)
                box = DO.NetworkCapture.shared.begin(request: task.originalRequest ?? request)
                if let body = Self.prefix(of: url) { box?.setRequestBody(body) }
                if let box = box { DO.NetworkTaskBox.attach(box, to: task) }
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        private func hookUploadWithFile(_ cls: AnyClass) {
            let selector = NSSelectorFromString("uploadTaskWithRequest:fromFile:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLRequest, URL) -> URLSessionUploadTask = { object, request, url in
                typealias Original = @convention(c) (AnyObject, Selector, URLRequest, URL) -> URLSessionUploadTask
                let task = DO.Swizzler.cast(original!, to: Original.self)(object, selector, request, url)
                DO.NetworkCapture.shared.attach(to: task, request: task.originalRequest ?? request)
                if let body = Self.prefix(of: url) {
                    DO.NetworkTaskBox.box(for: task)?.setRequestBody(body)
                }
                return task
            }

            original = DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
        }

        // MARK: - Delegate hooks

        private func hookDidReceiveData(_ cls: AnyClass) {
            let selector = NSSelectorFromString("URLSession:dataTask:didReceiveData:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLSession, URLSessionDataTask, Data) -> Void = { object, session, task, data in
                DO.NetworkTaskBox.box(for: task)?.append(data)

                guard let original = original else { return }
                typealias Original = @convention(c) (AnyObject, Selector, URLSession, URLSessionDataTask, Data) -> Void
                DO.Swizzler.cast(original, to: Original.self)(object, selector, session, task, data)
            }

            original = install(hook, on: cls, selector: selector, source: DO.NetworkSessionDelegate.self)
        }

        private func hookDidCompleteWithError(_ cls: AnyClass) {
            let selector = NSSelectorFromString("URLSession:task:didCompleteWithError:")
            var original: IMP?

            let hook: @convention(block) (AnyObject, URLSession, URLSessionTask, Error?) -> Void = { object, session, task, error in
                if let box = DO.NetworkTaskBox.box(for: task) {
                    DO.NetworkCapture.shared.commit(box, response: task.response, error: error)
                }

                guard let original = original else { return }
                typealias Original = @convention(c) (AnyObject, Selector, URLSession, URLSessionTask, Error?) -> Void
                DO.Swizzler.cast(original, to: Original.self)(object, selector, session, task, error)
            }

            original = install(hook, on: cls, selector: selector, source: DO.NetworkSessionDelegate.self)
        }

        /// Replaces the method when the class already has it; otherwise copies our
        /// implementation in so the callback starts being delivered at all.
        ///
        /// Without the second branch a delegate that never implemented `didReceiveData:`
        /// would simply never be asked for data — the runtime checks `respondsToSelector`.
        private func install(_ hook: Any, on cls: AnyClass, selector: Selector, source: AnyClass) -> IMP? {
            if class_getInstanceMethod(cls, selector) != nil {
                return DO.Swizzler.replaceInstanceMethod(of: cls, selector, with: hook)
            }
            guard let method = class_getInstanceMethod(source, selector) else { return nil }
            class_addMethod(cls, selector, imp_implementationWithBlock(hook), method_getTypeEncoding(method))
            return nil
        }

        // MARK: - Helpers

        private static func prefix(of url: URL) -> Data? {
            guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
            defer { try? handle.close() }
            return handle.readData(ofLength: DO.NetworkBody.maxBytes)
        }
    }
}
