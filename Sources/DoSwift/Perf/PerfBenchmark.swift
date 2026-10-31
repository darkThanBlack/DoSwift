//
//  PerfBenchmark.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit
import Darwin

extension DO {

    final class PerfBenchmark {

        static func run() {
            queue.asyncAfter(deadline: .now() + 1.5) {
                report()
            }
        }

        private static let queue = DispatchQueue(label: "com.doswift.perf.benchmark", qos: .userInitiated)

        private static func report() {
            print("=== DO.PerfBenchmark ===")
            print("device \(machineCode()) · iOS \(UIDevice.current.systemVersion) · threads \(threadCount())")
            print("task_vm_info_data_t = \(MemoryLayout<task_vm_info_data_t>.size) B, "
                + "task_basic_info = \(MemoryLayout<task_basic_info>.size) B, "
                + "malloc_statistics_t = \(MemoryLayout<malloc_statistics_t>.size) B")

            measure("task_info(TASK_VM_INFO)",              100_000) { vmInfo() }
            measure("task_info(TASK_BASIC_INFO)",           100_000) { basicInfo() }
            measure("task_threads(逐线程 CPU，原版 DoKit 用法)", 5_000) { cpuViaThreads() }
            measure("malloc_zone_statistics(default)",        5_000) { zoneStats(everyZone: false) }
            measure("malloc_zone_statistics(nil=全部 zone)",   5_000) { zoneStats(everyZone: true) }
            measure("mstats()  ← Firebase 用的",               5_000) { legacyStats() }
            measure("os_proc_available_memory()",           100_000) { UInt64(os_proc_available_memory()) }
            measure("mach_absolute_time（基线）",           100_000) { mach_absolute_time() }

            print("=== DO.PerfBenchmark 完 · 连跑三次看稳定性，首次可能含缺页 ===")
        }

        private static func vmInfo() -> UInt64 {
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(
                MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
            )
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }
            return result == KERN_SUCCESS ? UInt64(info.phys_footprint) : 0
        }

        private static func basicInfo() -> UInt64 {
            var info = task_basic_info()
            var count = mach_msg_type_number_t(
                MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size
            )
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &count)
                }
            }
            return result == KERN_SUCCESS ? UInt64(info.resident_size) : 0
        }

        private static func cpuViaThreads() -> UInt64 {
            var threads: thread_act_array_t?
            var count: mach_msg_type_number_t = 0
            guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS,
                  let list = threads else { return 0 }

            defer {
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(UInt(bitPattern: list)),
                    vm_size_t(Int(count) * MemoryLayout<thread_t>.stride)
                )
            }

            var total: UInt64 = 0
            for index in 0..<Int(count) {
                var info = thread_basic_info()
                var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let result = withUnsafeMutablePointer(to: &info) { pointer in
                    pointer.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                        thread_info(list[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                    }
                }
                if result == KERN_SUCCESS {
                    total &+= UInt64(info.cpu_usage)
                }
            }
            return total
        }

        private static func zoneStats(everyZone: Bool) -> UInt64 {
            var stats = malloc_statistics_t()
            malloc_zone_statistics(everyZone ? nil : malloc_default_zone(), &stats)
            return UInt64(stats.size_in_use)
        }

        private static func legacyStats() -> UInt64 {
            return UInt64(mstats().bytes_used)
        }

        private static let timebase: Double = {
            var info = mach_timebase_info_data_t()
            mach_timebase_info(&info)
            return Double(info.numer) / Double(info.denom)
        }()

        private static var sink: UInt64 = 0

        private static func measure(_ name: String, _ iterations: Int, _ body: () -> UInt64) {
            for _ in 0..<2_000 { sink &+= body() }

            var best = UInt64.max
            for _ in 0..<3 {
                var accumulator: UInt64 = 0
                let start = mach_absolute_time()
                for _ in 0..<iterations { accumulator &+= body() }
                best = min(best, mach_absolute_time() - start)
                sink &+= accumulator
            }

            let nanoseconds = Double(best) * timebase / Double(iterations)
            print(String(format: "%-38@ %10.0f ns/op", name as NSString, nanoseconds))
        }

        private static func threadCount() -> Int {
            var threads: thread_act_array_t?
            var count: mach_msg_type_number_t = 0
            guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS else { return 0 }
            if let list = threads {
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(UInt(bitPattern: list)),
                    vm_size_t(Int(count) * MemoryLayout<thread_t>.stride)
                )
            }
            return Int(count)
        }

        private static func machineCode() -> String {
            var info = utsname()
            uname(&info)
            return withUnsafeBytes(of: &info.machine) { raw in
                String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
            }
        }
    }
}
