//
//  PerfTrendPlugin.swift
//  DoSwift
//

import UIKit

/// 显示样式在 UserDefaults 里的 key
private let trendStyleKey = "kPerfTrendStyleKey"

/// 内存口径在 UserDefaults 里的 key
private let memoryMetricKey = "kPerfMemoryMetricKey"

final class PerfTrendPlugin: DO.DefaultPlugin {

    static let shared = PerfTrendPlugin()

    private init() {
        super.init(identifier: "performance", title: "性能", icon: UIImage(systemName: "gauge"))
    }

    /// 指标个数，顺序即默认顺序（与下面 `allCharts` 一致）
    static let metricCount = 3

    // MARK: - Sources

    private let frames = PerfFrameSource()
    private let cpu = PerfCpuSource()
    private let memory = PerfMemorySource()

    /// 三条曲线的全部，**顺序即默认顺序**。
    ///
    /// 标题、单位、量程、阈值都是展示参数，在这里字面量写死；源只提供它自己真正
    /// 用得上的 `interval` 和 `points`。加一个指标：加一个源类 + 在这里加一项。
    private var allCharts: [TrendChart] {
        // 总额拿到之前用一个占位，拿到之后量程和阈值一起换成真实的
        let memoryTotal = memory.totalMB ?? 512

        return [
            TrendChart(
                title: "FPS",
                unit: "fps",
                range: 0...frames.nominal,
                threshold: .below(frames.nominal * 0.75),
                interval: frames.interval,
                tint: .systemBlue,
                points: frames.points
            ),
            TrendChart(
                title: "CPU",
                unit: "%",
                range: 0...100,
                threshold: .above(80),
                interval: cpu.interval,
                tint: .systemOrange,
                points: cpu.points
            ),
            // 量程与阈值都由「总额」推出来：总额是这台设备给这个 App 划的线，
            // 阈值取它的 80%
            TrendChart(
                title: "内存",
                unit: "MB",
                range: 0...memoryTotal,
                threshold: .above(memoryTotal * 0.8),
                interval: memory.interval,
                tint: .systemGreen,
                points: memory.points
            ),
        ]
    }

    /// **已开启检测的**那几条，顺序不变。浮窗只认这个。
    var charts: [TrendChart] {
        return allCharts.enumerated()
            .filter { enabled.contains($0.offset) }
            .map(\.element)
    }

    /// CPU 的累计时间记录，详情页用它做差分算「累计 CPU 时间」。
    var cpuSamples: [PerfCpuSource.Sample] { cpu.samples }

    /// 内存分项（图形 / 媒体 / 网络）的原始记录，详情页按区间聚合要用。
    var memorySamples: [PerfMemorySource.Sample] { memory.samples }

    /// 内存总额（首次采样时确定，之后不变）
    var memoryTotalMB: Double? { memory.totalMB }

    /// 帧率的慢帧 / 冻结帧计数，详情页按区间求和要用。
    var frameSamples: [PerfFrameSource.Sample] { frames.samples }

    /// 某一条的全部信息，不受开关影响——详情页和设置页都要用它。
    func chart(at index: Int) -> TrendChart? {
        return allCharts.indices.contains(index) ? allCharts[index] : nil
    }

    // MARK: - State

    private(set) var isVisible = false

    /// 自己 present 的详情页。**自己记着**，不去 `presentedViewController` 里反推。
    private weak var report: UINavigationController?

    /// 折线模式下显示第几个指标。**稳定下标**（0/1/2），不随开关变化而重排。
    private(set) var currentIndex = 0

    /// 哪些指标在检测。**至少保留一个**。
    private(set) var enabled: Set<Int> = Set(0..<PerfTrendPlugin.metricCount)

    /// 内存的测量口径。**持久化**：上次选了堆口径，这次打开就该还是堆口径。
    private(set) var memoryMetric: PerfMemoryMetric = {
        let raw = UserDefaults.standard.string(forKey: memoryMetricKey)
        return raw.flatMap(PerfMemoryMetric.init(rawValue:)) ?? .footprint
    }()

    /// 展示形式。**持久化**：上次选了文字，这次打开就该还是文字。
    private(set) var displayStyle: TrendDisplayStyle = {
        let raw = UserDefaults.standard.string(forKey: trendStyleKey)
        return raw.flatMap(TrendDisplayStyle.init(rawValue:)) ?? .line
    }()
    
    private let trend = PerfTrendView()
    private var didLayout = false
    private var lastRefresh: TimeInterval = 0

    // MARK: - Public Interface

    func isEnabled(_ index: Int) -> Bool {
        return enabled.contains(index)
    }

    /// 开关某个指标的检测。**返回是否被接受**——最后一个不允许关。
    @discardableResult
    func setEnabled(_ isOn: Bool, for index: Int) -> Bool {
        guard index >= 0, index < PerfTrendPlugin.metricCount else { return false }

        if isOn {
            enabled.insert(index)
            startSource(index)
        } else {
            // 全部关掉之后浮窗没有可显示的东西，也没有可切换的下一个
            guard enabled.count > 1 else { return false }
            enabled.remove(index)
            stopSource(index)

            // 当前显示的那个被关掉了，按默认顺序挪到下一个还在检测的
            if !enabled.contains(currentIndex) {
                currentIndex = nextEnabled(after: currentIndex)
            }
        }

        refresh(force: true)
        return true
    }

    override func show() {
        super.show()

        isVisible = true
        layoutTrend()
        refresh(force: true)

        // 打开工具的落点是详情页，浮窗只是常驻的附属件。
        // 已经开着就不重复 present——`report` 是自己 present 的，不用去视图树里反推
        guard report == nil, let host = window?.rootViewController else { return }

        let navigator = UINavigationController(rootViewController: PerfReportViewController())
        // 禁掉下滑关闭，关闭只走导航栏那颗按钮——那条路上才有收尾逻辑
        navigator.isModalInPresentation = true
        host.present(navigator, animated: true)
        report = navigator
    }

    /// 关闭浮窗。设置页底部那颗按钮走这里。
    ///
    /// 与基类的差别只有一条：详情页开着时不能直接收窗口，否则会把用户正在看的页面一起带走。
    override func hide() {
        isVisible = false
        refresh(force: true)

        guard report == nil else { return }
        window?.isHidden = true
    }

    /// 换展示形式。**只动 UI**：数据一条都不碰，两种形式读的是同一批序列。
    /// 换内存口径。**会清空内存序列**——两个量的量纲都叫 MB，但描述的不是一回事。
    func setMemoryMetric(_ metric: PerfMemoryMetric) {
        guard metric != memoryMetric else { return }
        memoryMetric = metric
        UserDefaults.standard.set(metric.rawValue, forKey: memoryMetricKey)
        memory.setMetric(metric)
        refresh(force: true)
    }

    func setDisplayStyle(_ style: TrendDisplayStyle) {
        guard style != displayStyle else { return }
        displayStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: trendStyleKey)

        trend.style = style
        if trend.sizeToFitContent() {
            trend.settle(animated: false)
        }
        refresh(force: true)
    }

    /// 详情页关掉了。**显式清掉引用**，不等 weak 自动变 nil——
    /// `dismiss` 的 completion 里对象往往还没释放，那时判空会判错。
    func reportDidDismiss() {
        report = nil
        settingsDidDismiss()
    }

    func settingsDidDismiss() {
        guard !isVisible, report == nil else { return }
        window?.isHidden = true
    }

    // MARK: - Private

    override func makeWindow() -> DO.OverlayWindow {
        let overlay = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
        overlay.backgroundColor = .clear

        let host = UIViewController()
        host.view.backgroundColor = .clear
        overlay.rootViewController = host

        trend.style = displayStyle
        trend.delegate = self
        host.view.addSubview(trend)

        overlay.addNoResponseView(host.view)

        // 三个源各起各的时钟，**互不共享**。这里只接通知。
        // 显式挂调用点，不做一层「把所有源塞进数组再遍历」的抽象——
        // 三个源的类型不同，它们的共同点只有「有变化时说一声」。
        memory.setMetric(memoryMetric)

        frames.onChange = { [weak self] in self?.refresh() }
        cpu.onChange = { [weak self] in self?.refresh() }
        memory.onChange = { [weak self] in self?.refresh() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        startEnabledSources()
        didLayout = false

        // 一次性基准：给「内存 / CPU 该走哪条采样路径」提供真机数据。
        // 只打印，不改任何状态；进程内只跑一次（`show()` 有 `window == nil` 的闸）。
        // 结论定下来之后，这一行和 `PerfBenchmark.swift` 可以一起删掉。
        PerfBenchmark.run()

        return overlay
    }

    /// 按顺序找下一个**还在检测**的指标，循环。
    private func nextEnabled(after index: Int) -> Int {
        let order = (0..<PerfTrendPlugin.metricCount).filter { enabled.contains($0) }
        guard !order.isEmpty else { return 0 }
        guard let position = order.firstIndex(of: index) else { return order[0] }
        return order[(position + 1) % order.count]
    }

    // MARK: - 源启停

    /// 前后台切换由这里统一决定，不塞进每个源里——「什么时候该采」是同一件事。
    private func startEnabledSources() {
        for index in enabled {
            startSource(index)
        }
    }

    private func startSource(_ index: Int) {
        switch index {
        case 0: frames.start()
        case 1: cpu.start()
        case 2: memory.start()
        default: break
        }
    }

    private func stopSource(_ index: Int) {
        switch index {
        case 0: frames.stop()
        case 1: cpu.stop()
        case 2: memory.stop()
        default: break
        }
    }

    @objc private func applicationDidEnterBackground() {
        for index in 0..<PerfTrendPlugin.metricCount { stopSource(index) }
    }

    @objc private func applicationWillEnterForeground() {
        startEnabledSources()
    }

    // MARK: - 布局与重画

    private func layoutTrend() {
        guard let host = window?.rootViewController else { return }

        let size = trend.sizeThatFits(host.view.bounds.size)
        let saved = UserDefaults.standard.object(forKey: PerfTrendView.frameKey) as? [String: CGFloat]

        let fallback = CGPoint(x: host.view.bounds.width - size.width - 12, y: 60)
        let origin = saved.map { CGPoint(x: $0["x"] ?? fallback.x, y: $0["y"] ?? fallback.y) } ?? fallback

        trend.frame = CGRect(origin: origin, size: size)
        trend.settle(animated: false)
        didLayout = true
    }

    /// 重画。**刷新节奏归展示形式**：三个源的采样率不一样（10Hz / 10Hz / 1Hz），
    /// 谁变了都会来敲这里，但不同样式能承受的频率不同。
    ///
    /// - 折线：10Hz 可以，曲线本来是连续的
    /// - 文字：1Hz 足够。数字一秒跳十次读不了
    private func refresh(force: Bool = false) {
        guard isVisible else {
            trend.isHidden = true
            return
        }

        let now = CACurrentMediaTime()
        let minimum: TimeInterval = (displayStyle == .text) ? 1 : 0.1
        guard force || now - lastRefresh >= minimum else { return }
        lastRefresh = now

        trend.isHidden = false
        trend.render(current: chart(at: currentIndex), all: charts, now: now)

        if !trend.isDragging, trend.sizeToFitContent() {
            trend.settle(animated: false)
        }
    }
}

// MARK: - PerfTrendViewDelegate

extension PerfTrendPlugin: PerfTrendViewDelegate {

    /// 单击：按默认顺序换到下一个**还在检测**的指标。文字模式一行里已经全都在了，不响应。
    func perfTrendViewDidTap(_ view: PerfTrendView) {
        guard displayStyle == .line else { return }
        currentIndex = nextEnabled(after: currentIndex)
        refresh(force: true)
    }

    /// 长按：打开详情页。浮窗在详情页之上会被它盖住，但桌面上的入口只有这一个。
    func perfTrendViewDidLongPress(_ view: PerfTrendView) {
        show()
    }
}
