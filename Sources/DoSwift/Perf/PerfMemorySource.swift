//
//  PerfMemorySource.swift
//  DoSwift
//

import UIKit
import Darwin

/// 内存的两种测量口径。同一个页面上切换，用来对照。
enum PerfMemoryMetric: String, CaseIterable {

    /// `task_info(TASK_VM_INFO)` 的 `phys_footprint`：jetsam 真正看的量，
    /// 和 Xcode 内存面板同一口径。大图、视频帧这些 IOSurface 内存也算在里面。
    case footprint

    /// `mstats()` 的 `bytes_used`：malloc 堆。只覆盖 malloc 分出去的内存，
    /// 看不见 CG 图像和 mmap。
    case heap

    var title: String {
        switch self {
        case .footprint: return "进程占用"
        case .heap: return "堆分配"
        }
    }
}

final class PerfMemorySource {

    /// 一个采样点的完整记录。`points` 里只存了一个标量，这里存齐，供详情页按区间聚合。
    struct Sample {
        let t: TimeInterval
        /// 当前口径下的值（MB）
        let value: Double
        /// 该口径下的「总额」（MB）。进程口径 = 预算，堆口径 = arena 总量
        let budget: Double?
        /// 下面三项只有进程口径拿得到，堆口径下是 nil
        let graphics: Double?
        let media: Double?
        let network: Double?
    }

    let interval: TimeInterval = 0.1

    /// 当前口径。**切口径会清空序列**——两个量的量纲虽然都叫 MB，但描述的不是一回事，
    /// 混在一条曲线上就是错的。
    private(set) var metric: PerfMemoryMetric = .footprint

    /// 序列**只在主线程写、只在主线程读**
    private(set) var points: [TrendPoint] = []
    private(set) var samples: [Sample] = []

    /// **总额只确定一次**：预算 = footprint + 系统还能给多少。之后不再刷新——
    /// 它是这台设备给这个 App 划的线，不跟着用量走。首次采样之前是 nil。
    private(set) var totalMB: Double?

    var onChange: (() -> Void)?

    private let queue = DispatchQueue(label: "com.doswift.perf.memory")
    private var timer: DispatchSourceTimer?

    // MARK: - Life Cycle

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

    /// 换口径：清空历史，从下一点开始按新口径记。
    func setMetric(_ metric: PerfMemoryMetric) {
        guard metric != self.metric else { return }
        self.metric = metric
        points.removeAll()
        samples.removeAll()
        onChange?()
    }

    // MARK: - Sample

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
            self.points.append(TrendPoint(t: now, v: sample.value))
            self.samples.append(sample)
            if self.totalMB == nil {
                self.totalMB = sample.budget
            }
            self.onChange?()
        }
    }

    /// 进程口径：一次 mach trap 拿到 footprint、预算和三个 ledger 分项
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

        // 预算用 `os_proc_available_memory()` 而不是 `limit_bytes_remaining`：
        // 后者在 iOS 上实测为 0，算出来的「总额」等于当时的 footprint，看着像 bug。
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

    /// 堆口径：malloc 自己的账本。`mstats()` 内部就是 `malloc_zone_statistics(NULL, …)`。
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
