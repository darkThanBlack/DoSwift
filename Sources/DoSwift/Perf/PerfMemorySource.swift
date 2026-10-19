//
//  PerfMemorySource.swift
//  DoSwift
//

import UIKit
import Darwin

/// 堆内存占用。采集方式照抄 Firebase 的 `FPRMemoryGaugeCollector`：
/// **私有串行队列 + `dispatch_source` 定时器 + `mstats()`**。
///
/// `mstats()` 是 malloc 分配器自己的账本：`bytes_used` 是各 zone 已分配出去的字节，
/// `bytes_free` 是 zone 里还没分出去的空闲块。一次调用同时拿到两者，没有额外开销。
///
/// **它不是 jetsam 判据**。系统杀进程看的是 `phys_footprint`（含 IOSurface、
/// CG 图像、mmap 这些 malloc 管不到的部分），而 `bytes_free` 只是分配器手头的余量。
/// 所以这里的曲线回答的是「堆在怎么长」，不是「离被杀还有多远」。
///
/// 下一步会叠加 `os_proc_available_memory()` 作为**新的一个字段**——它和这里的
/// 两个字段并列，不是二选一：一个说堆的趋势，一个说系统额度。
final class PerfMemorySource {

    let interval: TimeInterval = 0.1

    /// 序列**只在主线程写、只在主线程读**
    private(set) var points: [TrendPoint] = []

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

    /// 进后台就停，理由同 `PerfCpuSource.stop()`
    func stop() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Sample

    private func sample() {
        let stats = mstats()
        let used = Double(stats.bytes_used) / 1024 / 1024
        let now = CACurrentMediaTime()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.points.append(TrendPoint(t: now, v: used))
            self.onChange?()
        }
    }
}
