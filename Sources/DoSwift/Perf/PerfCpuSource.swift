//
//  PerfCpuSource.swift
//  DoSwift
//

import UIKit

/// CPU 占用。采集方式照抄 Firebase 的 `FPRCPUGaugeCollector`：
/// **私有串行队列 + `dispatch_source` 定时器 + 进程累计 CPU 时间**。
///
/// 存的是「两次采样之间消耗了多少 CPU 时间」换算出的百分比，而不是逐线程求和。
/// 好处是口径和系统一致（`task_basic_info` 由内核维护），也不会在每次采样时
/// 遍历几十个线程。
///
/// 百分比按**单核心口径**：100% = 一个核心跑满（和 Instruments 一致，多核可以超，
/// 这里夹到 100）。Firebase 存的是原始微秒数、由后端算比例；我们只在本机展示，
/// 所以在采集时就换算好，存进去的仍是「原始比例」而不是聚合值。
final class PerfCpuSource {

    /// 采样间隔。Firebase 前台默认 100ms
    let interval: TimeInterval = 0.1

    /// 序列**只在主线程写、只在主线程读**。采样在私有队列上，采完投回主线程再写。
    private(set) var points: [TrendPoint] = []

    var onChange: (() -> Void)?

    private let queue = DispatchQueue(label: "com.doswift.perf.cpu")
    private var timer: DispatchSourceTimer?

    /// 只在这条队列上读写
    private var last: (user: UInt64, system: UInt64, t: TimeInterval)?

    // MARK: - Life Cycle

    func start() {
        guard timer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in self?.sample() }
        timer.resume()
        self.timer = timer
    }

    /// 进后台就停。定时器在挂起期间本来也跑不了，但「活着但没用」的那段时间
    /// 会往序列里写一堆后台数据，回来时全是要丢的噪音——Firebase 同样在后台归零。
    func stop() {
        timer?.cancel()
        timer = nil
        // `last` 只在队列上读写，复位也放到队列上，避免和正在跑的采样抢
        queue.async { [weak self] in self?.last = nil }
    }

    // MARK: - Sample

    private func sample() {
        guard let times = Self.cpuTimes() else { return }

        let now = CACurrentMediaTime()
        defer { last = (times.user, times.system, now) }
        // 第一跳只立基准：还没有「过去的一格」可以算
        guard let previous = last else { return }

        let consumed = Double(times.user - previous.user) + Double(times.system - previous.system)
        let elapsed = now - previous.t
        guard elapsed > 0 else { return }

        // 夹到 100：多核下单核心口径能超过 100%，这一段见类型注释
        let percent = min(consumed / (elapsed * 1_000_000) * 100, 100)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.points.append(TrendPoint(t: now, v: percent))
            self.onChange?()
        }
    }

    /// 进程累计的 user + system CPU 时间（微秒）。
    private static func cpuTimes() -> (user: UInt64, system: UInt64)? {
        var info = task_basic_info()
        // `TASK_BASIC_INFO_COUNT` 是 C 宏，Swift 里不可用，按它的定义自己算
        var count = mach_msg_type_number_t(
            MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let user = UInt64(info.user_time.seconds) * 1_000_000 + UInt64(info.user_time.microseconds)
        let system = UInt64(info.system_time.seconds) * 1_000_000 + UInt64(info.system_time.microseconds)
        return (user, system)
    }
}
