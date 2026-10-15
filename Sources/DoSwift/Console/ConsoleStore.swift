//
//  ConsoleStore.swift
//  DoSwift
//

import Foundation

/// 两条链路的汇合点，同时也是**全部筛选状态**的所在地。
///
/// 页面只做两件事：把 `visibleLines()` 翻成分组、把交互转成对这里的调用。
/// 上限、暂停、筛选都在这儿，于是「设置页改了但列表没跟着变」这类问题不会出现
/// ——两处读的是同一份状态。
final class ConsoleStore {

    static let shared = ConsoleStore()

    private init() {
        capture.onLine = { [weak self] line in
            self?.append(line)
        }
        capture.onContinuation = { [weak self] source, text in
            self?.appendContinuation(text, from: source)
        }
        unifiedLog.onLines = { [weak self] lines in
            lines.forEach { self?.append($0) }
        }
    }

    // MARK: - 采集

    let capture = ConsoleCapture.shared

    let unifiedLog = ConsoleUnifiedLog()

    /// 挂上 fd 接管。**幂等**，由 `ConsolePlugin.show()` 每次调一次。
    ///
    /// 只在用户第一次打开控制台时才真的接管，之后就一直挂着。代价是两件全局副作用
    /// （fd 1/2 被改指管道、stdio 改成行缓冲），不打开这个工具的人一分钱都不付；
    /// 而一旦打开过，日志就得一直攒着——不然「打几条日志再打开工具看」这个最自然的
    /// 用法根本不成立。
    func startCollecting() {
        capture.start()
    }

    // MARK: - 筛选

    struct Filter {
        /// 哪几条链路要显示
        var sources: Set<ConsoleLine.Source> = Set(ConsoleLine.Source.allCases)

        /// 关键字，空 = 不过滤。匹配的是行正文
        var keyword: String = ""

        /// 统一日志里「没有 subsystem」的条目要不要收
        var includesEmptySubsystem: Bool = true
    }

    /// 只在主线程读写（搜索框、设置页、刷表），所以不必上锁。
    var filter = Filter() {
        didSet { notify() }
    }

    /// 暂停 = **不再追加**。
    ///
    /// 不是「不刷新界面」：缓冲有上限，继续追加会把正在看的那几行挤掉，
    /// 屏幕上就成了一份一直在变的快照。停追加才是真的冻住。
    ///
    /// 注意**管道照旧排空**（`ConsoleCapture` 照常读），这一步不能省：
    /// 管道满了以后写端会**阻塞调用线程**，那是把宿主 App 卡死，不是丢几条日志。
    ///
    /// 读写都在 `lock` 里：写来自主线程，读来自捕获队列。
    /// （`NSLock` 不是可重入锁，所以 `append` 里直接看 `pausedStorage`，不再走这个 getter。）
    private var pausedStorage = false

    var isPaused: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return pausedStorage
        }
        set {
            lock.lock()
            pausedStorage = newValue
            lock.unlock()

            notify()
        }
    }

    // MARK: - 缓冲

    /// 缓存上限。设备上的调试工具，缓冲必须有界——这不是性能取舍，是内存安全。
    private let limit = 2000

    /// 单行显示上限
    private let maxTextLength = 4000

    private let lock = NSLock()

    /// 内容变了要刷表（主线程）
    var onChange: (() -> Void)?

    /// 时间正序存放
    private var buffer: [ConsoleLine] = []

    // MARK: - 写入

    func append(_ line: ConsoleLine) {
        lock.lock()
        guard !pausedStorage else {
            lock.unlock()
            return
        }

        var line = line
        line.setText(line.text, limit: maxTextLength)
        buffer.append(line)
        if buffer.count > limit {
            buffer.removeFirst(buffer.count - limit)
        }
        lock.unlock()

        notify()
    }

    /// 续行：并进**上一条记录的正文**，不另起一行。
    ///
    /// 一条记录被拆成多行的情况只有一种（见 `ConsoleCapture.deliver`）：ObjC 老式多行
    /// description。并回去之后，列表里是一条、详情页里是原样的多行。
    func appendContinuation(_ text: String, from source: ConsoleLine.Source) {
        lock.lock()
        if !pausedStorage, let last = buffer.last, last.source == source {
            var merged = last
            merged.appendContinuation(text, limit: maxTextLength)
            buffer[buffer.count - 1] = merged
            lock.unlock()

            notify()
            return
        }
        lock.unlock()

        // 并不进去就**当成独立一行**，绝不丢。会走到这里是因为中间被别的来源插了一条
        // （统一日志是另一条队列），此时「上一条」已经不是它的上一条了。
        append(ConsoleLine(date: Date(), source: source, text: text))
    }

    // MARK: - 读取

    /// 捕获到的总行数（含被筛掉的），状态栏用
    var capturedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffer.count
    }

    /// 当前该显示的：先按筛选取，再**倒序**（最新的在最上面）。
    ///
    /// 倒序而不是「正序 + 自动滚到底」：日志一直在来，跟用户抢滚动条是打不完的架；
    /// 最新在最上面就永远不用滚。
    func visibleLines() -> [ConsoleLine] {
        lock.lock()
        let snapshot = buffer
        lock.unlock()

        let keyword = filter.keyword.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = snapshot.filter { line in
            guard filter.sources.contains(line.source) else { return false }
            guard !keyword.isEmpty else { return true }
            return line.text.lowercased().contains(keyword)
        }
        return filtered.reversed()
    }

    /// 导出用的全文：**照时间正序**，与控制台里从上往下读的顺序一致
    func exportText() -> String {
        lock.lock()
        let snapshot = buffer
        lock.unlock()

        return snapshot
            .map { "[\($0.metaText)] \($0.text)" }
            .joined(separator: "\n")
    }

    func clear() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()

        notify()
    }

    // MARK: - 通知

    private let notifyLock = NSLock()
    private var isNotifyScheduled = false
    private var lastNotify = Date.distantPast

    /// 两次刷表之间的最小间隔。
    ///
    /// 一次刷表的固定开销实测约 6 ms（`visibleLines` 0.47 + 每行 `metaText` 2.14 +
    /// 2000 个行闭包 2.35 + 基类每行算一遍 reuse id 1.02），再加上 UIKit 自己的
    /// `reloadData`。日志密集时按主线程的节奏刷（一秒几十次）就等于把主线程缴了。
    ///
    /// 节流到 5 次/秒：既看不出延迟，也不会让表在手指底下不停换行。
    private let minNotifyInterval: TimeInterval = 0.2

    /// 合并 + 节流刷新。
    ///
    /// 日志是连续的流，一行一次 `reloadData` 会让表根本没法滚。这里做两件事：
    /// 这一轮里攒下的所有变化只触发一次刷新；且两次刷新之间至少隔 `minNotifyInterval`。
    private func notify() {
        notifyLock.lock()
        if isNotifyScheduled {
            notifyLock.unlock()
            return
        }
        isNotifyScheduled = true

        // 距上次刷表还不够久的话，把这一次顺延到够久为止（顺延期间来的变化一起并进去）
        let wait = minNotifyInterval - Date().timeIntervalSince(lastNotify)
        notifyLock.unlock()

        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, wait)) { [weak self] in
            guard let self = self else { return }
            self.notifyLock.lock()
            self.isNotifyScheduled = false
            self.lastNotify = Date()
            self.notifyLock.unlock()

            self.onChange?()
        }
    }
}
