//
//  PerfCpuSource.swift
//  DoSwift
//

import UIKit

/// CPU 占用。采集方式与 Firebase 的 `fprCollectCPUMetric()` **逐行对应**：
///
/// 1. 读 `TASK_BASIC_INFO` 拿任务级的累计 user / system 时间
/// 2. 遍历 `task_threads`，跳过 idle 线程，把每个线程的累计时间再加进去
///
/// 两段相加是 Firebase 的写法。任务级那段记录的是**已经退出的线程**消耗的时间
/// ——它们在 `task_threads` 里已经看不到了。
///
/// 实测提醒：在 iOS 26.5 上任务级那个字段不更新（37 秒里读到的值一模一样），
/// 所以动的是第二段。两段相加不影响任何差值——单次占比、累计时间、平均占用
/// 都是差值，常量会被消掉。
///
/// 代价：约 8.6–11.8µs（随线程数线性），比只读任务级字段贵十倍。按 10Hz 算
/// 约 0.01% CPU。
///
/// 百分比按**单核心口径**：100% = 一个核心跑满（和 Instruments 一致，多核可以超，
/// 这里夹到 100）。Firebase 存的是原始微秒数、由后端算比例；我们只在本机展示，
/// 所以在采集时就换算好，存进去的仍是「原始比例」而不是聚合值。
final class PerfCpuSource {

    /// 一个采样点的原始记录：**进程累计的 user / system CPU 时间**（微秒）。
    ///
    /// 详情页的「累计 CPU 时间」直接取首尾两个累计值的差——不按占比做积分。
    /// 积分对采样密度、定时器抖动、断档都敏感，而累计值由内核维护，差分是精确的。
    struct Sample {
        let t: TimeInterval
        let user: UInt64
        let system: UInt64

        var totalUsec: UInt64 { user &+ system }
    }

    /// 采样间隔。Firebase 前台默认 100ms
    let interval: TimeInterval = 0.1

    /// 序列**只在主线程写、只在主线程读**。采样在私有队列上，采完投回主线程再写。
    private(set) var points: [TrendPoint] = []

    /// 每一次采样的累计时间，含第一跳（它只立基准，不产出占比点）
    private(set) var samples: [Sample] = []

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
        let previous = last
        last = (times.user, times.system, now)

        // 第一跳没有基准可减，只记累计值、不产出占比点
        var percent: Double?
        if let previous = previous {
            // 线程退出会让总和变小，这时按 0 处理，不要用无符号减法绕回去
            let current = times.user + times.system
            let before = previous.user + previous.system
            let consumed = current >= before ? Double(current - before) : 0
            let elapsed = now - previous.t
            if elapsed > 0 {
                // 夹到 100：多核下单核心口径能超过 100%，这一段见类型注释
                percent = min(consumed / (elapsed * 1_000_000) * 100, 100)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.samples.append(Sample(t: now, user: times.user, system: times.system))
            if let percent = percent {
                self.points.append(TrendPoint(t: now, v: percent))
            }
            self.onChange?()
        }
    }

    /// 进程累计的 user + system CPU 时间（微秒）。
    /// 任务级 + 各非 idle 线程的累计 user / system CPU 时间（微秒）。
    ///
    /// 与 Firebase 一致：任何一步失败都返回 nil，这一格不记。
    /// 已退出的线程不在 `task_threads` 里，它们的时间由任务级字段贡献。
    private static func cpuTimes() -> (user: UInt64, system: UInt64)? {
        // 1. 任务级累计时间
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

        // 2. 逐个线程累加
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
