//
//  PerfFrameSource.swift
//  DoSwift
//

import UIKit

/// 帧率。采集方式照抄 Firebase 的 `FPRScreenTraceTracker`：**主线程 `CADisplayLink`，
/// 逐帧量相邻 timestamp 的间隔**，超过阈值就记一次慢帧（或冻结帧）。
///
/// 与 Firebase 的差别有两处，都是有意的：
///
/// 1. **慢帧阈值按屏幕刷新率算**，不用它写死的 `1/59`。在 120Hz 的 ProMotion 设备上，
///    `1/59 ≈ 16.95ms`，而 60fps 的一帧正好 16.67ms——「120 掉到 60」这种最常见的
///    降级它判不出来。
/// 2. **它只产出计数，我们还要产出曲线**，所以每秒结算一个点：这一秒没有慢帧就报
///    额定刷新率（定时器抖动不该让一条本该平直的线变成 59.8、60.2），有慢帧才报
///    实测值。曲线的凹陷因此只表示「真掉了」。
///
/// 慢帧 / 冻结帧的计数留在源里，给将来的柱状图用；当前的点对象只有帧率一个数，
/// 这是刻意的——不同指标的原始记录形状不同，硬抽成一个会丢信息。
final class PerfFrameSource {

    /// 每秒结算一个点
    let interval: TimeInterval = 1

    /// 序列**只在主线程写、只在主线程读**（display link 本来就在主线程）
    private(set) var points: [TrendPoint] = []

    var onChange: (() -> Void)?

    /// 屏幕的额定刷新率，创建时读一次。**对外可见**：量程和阈值都按它算，
    /// 而那是展示参数，由 plugin 构造 `TrendChart` 时用。
    let nominal: Double

    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var windowStart: CFTimeInterval = 0
    private var frames = 0
    private var slowFrames = 0
    private var frozenFrames = 0

    init() {
        let screen = DoSwiftCore.shared.appWindow?.windowScene?.screen ?? UIScreen.main
        nominal = Double(max(screen.maximumFramesPerSecond, 60))
    }

    // MARK: - Life Cycle

    func start() {
        guard link == nil else { return }

        resetWindow()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    /// 进后台就停。display link 在挂起期间不再回调，但前后台切换的边界要处理干净：
    /// 否则回来第一帧的 delta 会横跨整段后台时间，直接被算成一次冻结帧。
    func stop() {
        link?.invalidate()
        link = nil
        resetWindow()
    }

    private func resetWindow() {
        lastTimestamp = 0
        windowStart = CACurrentMediaTime()
        frames = 0
        slowFrames = 0
        frozenFrames = 0
    }

    // MARK: - Frame

    /// 慢帧阈值：比额定帧间隔多一点点。`1/60` 是 16.67ms，取 `1/59` 会在 120Hz 设备上
    /// 把正常的一帧判成慢帧，所以按自己的额定刷新率算。
    private var slowThreshold: CFTimeInterval {
        return 1.0 / max(nominal - 1, 1)
    }

    /// 冻结帧：Firebase 的 700ms，保留
    private let frozenThreshold: CFTimeInterval = 0.7

    @objc private func tick(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        defer { lastTimestamp = now }

        // 第一帧没有「上一帧」可比
        guard lastTimestamp > 0 else { return }

        let delta = now - lastTimestamp
        frames += 1
        if delta > frozenThreshold {
            frozenFrames += 1
            slowFrames += 1
        } else if delta > slowThreshold {
            slowFrames += 1
        }

        let elapsed = now - windowStart
        guard elapsed >= interval else { return }

        let measured = Double(frames) / elapsed
        // 没有慢帧就报额定值——见文件头第 2 条
        let value = slowFrames == 0 ? nominal : measured

        points.append(TrendPoint(t: now, v: value))

        frames = 0
        slowFrames = 0
        frozenFrames = 0
        windowStart = now

        onChange?()
    }
}
