//
//  PerfCpuSource.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    final class PerfCpuSource {

        struct Sample {
            let t: TimeInterval
            let user: UInt64
            let system: UInt64

            var totalUsec: UInt64 { user &+ system }
        }

        let interval: TimeInterval = 0.1

        private(set) var points: [DO.TrendPoint] = []

        private(set) var samples: [Sample] = []

        var onChange: (() -> Void)?

        private let queue = DispatchQueue(label: "com.doswift.perf.cpu")
        private var timer: DispatchSourceTimer?

        private var last: (user: UInt64, system: UInt64, t: TimeInterval)?

        func start() {
            guard timer == nil else { return }

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(50))
            timer.setEventHandler { [weak self] in self?.sample() }
            timer.resume()
            self.timer = timer
        }

        func stop() {
            timer?.cancel()
            timer = nil
            queue.async { [weak self] in self?.last = nil }
        }

        private func sample() {
            guard let times = Self.cpuTimes() else { return }

            let now = CACurrentMediaTime()
            let previous = last
            last = (times.user, times.system, now)

            var percent: Double?
            if let previous = previous {
                let current = times.user + times.system
                let before = previous.user + previous.system
                let consumed = current >= before ? Double(current - before) : 0
                let elapsed = now - previous.t
                if elapsed > 0 {
                    percent = min(consumed / (elapsed * 1_000_000) * 100, 100)
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.samples.append(Sample(t: now, user: times.user, system: times.system))
                if let percent = percent {
                    self.points.append(DO.TrendPoint(t: now, v: percent))
                }
                DO.PerfHistory.trim(&self.samples)
                DO.PerfHistory.trim(&self.points)
                self.onChange?()
            }
        }

        private static func cpuTimes() -> (user: UInt64, system: UInt64)? {
            var taskInfo = task_basic_info()
            var taskInfoCount = mach_msg_type_number_t(
                MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size
            )
            let taskResult = withUnsafeMutablePointer(to: &taskInfo) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(taskInfoCount)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &taskInfoCount)
                }
            }
            guard taskResult == KERN_SUCCESS else { return nil }

            var user = UInt64(taskInfo.user_time.seconds) * 1_000_000
                + UInt64(taskInfo.user_time.microseconds)
            var system = UInt64(taskInfo.system_time.seconds) * 1_000_000
                + UInt64(taskInfo.system_time.microseconds)

            var threads: thread_act_array_t?
            var threadCount: mach_msg_type_number_t = 0
            guard task_threads(mach_task_self_, &threads, &threadCount) == KERN_SUCCESS,
                  let list = threads else { return nil }

            defer {
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(UInt(bitPattern: list)),
                    vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
                )
            }

            for index in 0..<Int(threadCount) {
                var info = thread_basic_info()
                var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let result = withUnsafeMutablePointer(to: &info) { pointer in
                    pointer.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                        thread_info(list[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                    }
                }
                guard result == KERN_SUCCESS else { return nil }
                guard info.flags & TH_FLAGS_IDLE == 0 else { continue }

                user += UInt64(info.user_time.seconds) * 1_000_000
                    + UInt64(info.user_time.microseconds)
                system += UInt64(info.system_time.seconds) * 1_000_000
                    + UInt64(info.system_time.microseconds)
            }
            return (user, system)
        }
    }
}
