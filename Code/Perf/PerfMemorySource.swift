//
//  PerfMemorySource.swift
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

    enum PerfMemoryMetric: String, CaseIterable {

        case footprint

        case heap

        var title: String {
            switch self {
            case .footprint: return DO.Text.Perf.memoryFootprint
            case .heap: return DO.Text.Perf.memoryHeap
            }
        }
    }

    final class PerfMemorySource {

        struct Sample {
            let t: TimeInterval
            let value: Double
            let budget: Double?
            let graphics: Double?
            let media: Double?
            let network: Double?
        }

        let interval: TimeInterval = 0.1

        private(set) var metric: DO.PerfMemoryMetric = .footprint

        private(set) var points: [DO.TrendPoint] = []
        private(set) var samples: [Sample] = []

        private(set) var totalMB: Double?

        var onChange: (() -> Void)?

        private let queue = DispatchQueue(label: "com.doswift.perf.memory")
        private var timer: DispatchSourceTimer?

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
        }

        func setMetric(_ metric: DO.PerfMemoryMetric) {
            guard metric != self.metric else { return }
            self.metric = metric
            points.removeAll()
            samples.removeAll()
            onChange?()
        }

        private func sample() {
            let now = CACurrentMediaTime()
            let value: Sample?
            switch metric {
            case .footprint: value = Self.footprintSample(at: now)
            case .heap:      value = Self.heapSample(at: now)
            }
            guard let sample = value else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.points.append(DO.TrendPoint(t: now, v: sample.value))
                self.samples.append(sample)
                DO.PerfHistory.trim(&self.points)
                DO.PerfHistory.trim(&self.samples)
                if self.totalMB == nil {
                    self.totalMB = sample.budget
                }
                self.onChange?()
            }
        }

        private static func footprintSample(at time: TimeInterval) -> Sample? {
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(
                MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
            )
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }
            guard result == KERN_SUCCESS else { return nil }

            let unit = 1024.0 * 1024.0
            let footprint = Double(info.phys_footprint) / unit

            let remaining = Double(os_proc_available_memory()) / unit

            return Sample(
                t: time,
                value: footprint,
                budget: footprint + remaining,
                graphics: Double(info.ledger_tag_graphics_footprint) / unit,
                media: Double(info.ledger_tag_media_footprint) / unit,
                network: Double(info.ledger_tag_network_nonvolatile + info.ledger_tag_network_volatile) / unit
            )
        }

        private static func heapSample(at time: TimeInterval) -> Sample? {
            let stats = mstats()
            let unit = 1024.0 * 1024.0
            return Sample(
                t: time,
                value: Double(stats.bytes_used) / unit,
                budget: Double(stats.bytes_total) / unit,
                graphics: nil,
                media: nil,
                network: nil
            )
        }
    }
}
