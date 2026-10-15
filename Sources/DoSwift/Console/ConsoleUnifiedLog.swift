//
//  ConsoleUnifiedLog.swift
//  DoSwift
//

import Foundation
import OSLog

/// 统一日志（`os_log` / `Logger`）的**回读**。
///
/// 这条路和 fd 那条完全无关，两者是互补的、不是叠加的。实测：
///
/// | 记日志的写法 | fd 1 / fd 2 | 统一日志 |
/// |---|---|---|
/// | `print` | ✅ | ❌ 一个字都没有 |
/// | `NSLog` | ✅ | 有，但内容是 `<private>` 空壳 |
/// | `Logger`（不挂调试器）| ❌ | ✅ |
/// | `Logger`（挂着调试器）| ✅ | ✅ |
///
/// 最后一行是本文件存在的理由：**Xcode 开着的时候，fd 2 已经把 `Logger` 的内容带出来了**，
/// 这时再回读就是重复；而**没有调试器时**（真机点图标启动、给别人测），fd 那边只剩
/// `NSLog` 和 `print`，`Logger` 只有这里拿得到。
///
/// ## 为什么是「按需查询」而不是「定时轮询」
///
/// 因为它**一次查询恒定约 1 秒**——实测（macOS 26，裸可执行文件和装进 .app 各测一遍）：
///
/// ```
/// 一条日志都没有的进程   getEntries → 1039 ms
/// 打了 3000 条的进程     getEntries → 1101 ms
/// 同一个 store 连查三次      1024 / 1016 / 1029 ms   ← 不缓存
/// 真正迭代那一步             0.0 ms                  ← 代价全在「查询」这个调用本身
/// ```
///
/// 与条目量无关、与 `position` 无关、加 `NSPredicate` 也压不下去（全都试过）。
/// 所以第一版把它挂在主线程的 1 秒 Timer 上时，等于每秒堵死主线程一秒——页面卡到不能用。
///
/// 于是这里的形状是被实测逼出来的两条：
/// - **在后台队列上查**（`queryQueue`）。这条不管代价多大都成立，主线程不能碰它。
/// - **不自动重复**。页面打开时查一次，之后由用户点一下查一次。定时的代价是
///   永久占住一个核，而收益只是「不用点一下」。
///
/// ## 三条限制
///
/// - **iOS 15 起才有。** `Store.h`：`storeWithScope:` 是 `API_AVAILABLE(ios(15.0))`；
///   而 `localStoreAndReturnError` 干脆是 `API_UNAVAILABLE(ios, tvos, watchos)`
///   ——「读本机全部日志」那条路在 iOS 上根本不存在。部署目标是 13，所以处处要兜。
/// - **只能读本进程**，scope 就是 `.currentProcessIdentifier`。不需要任何 entitlement。
/// - **插值默认被掩成 `<private>`。** 实测 `log.info("x \(s)")` 回读到 `x <private>`，
///   只有显式写 `privacy: .public` 或者数字才看得见。这是系统行为，改不了。
final class ConsoleUnifiedLog {

    /// 这台设备上这条路走不走得通。设置页要拿它决定「给开关还是给一句说明」。
    static var isAvailable: Bool {
        if #available(iOS 15.0, *) { return true }
        return false
    }

    /// 只收本 App 的：`subsystem == Bundle.main.bundleIdentifier`。
    ///
    /// 必须有这一条。实测一个只做了几件 Foundation 常规操作的小程序，**自己进程里**
    /// 有一条 `com.apple.xpc` / `CFNetwork` / `CarbonCore` / `network` 各若干——
    /// 它们是「你替 Apple 框架打的」，所以「只看本进程」挡不住，只有 subsystem 能筛。
    var subsystem = Bundle.main.bundleIdentifier ?? ""

    /// 裸 `Logger()` 的 subsystem 是**空串**（实测，即使 bundle id 非空），
    /// 所以「没有 subsystem」的条目既可能是业务偷懒写的、也可能是框架打的。
    /// 默认收进来（调试工具宁可多给），设置页里可以关。
    var includesEmptySubsystem = true

    /// 收到新条目时回调。**在查询队列上**——`ConsoleStore.append` 是带锁的，
    /// 与 fd 那条链路从捕获队列进来是同一种用法。
    var onLines: (([ConsoleLine]) -> Void)?

    /// 查询开始 / 结束（主线程）。页面拿它把按钮切成「查询中」。
    var onStateChange: (() -> Void)?

    /// 上一次查询花了多久。状态栏拿它解释「为什么要手动点」
    private(set) var lastDuration: TimeInterval = 0

    private(set) var isRefreshing = false

    private let queryQueue = DispatchQueue(label: "com.doswift.console.unifiedlog")

    /// 已经读到哪个时刻了。
    ///
    /// 必须自己记：`getEntries(with:at:matching:)` 有个 Apple 论坛在册的 bug
    /// （r. 87416514）——**它不理会 position 参数**，永远返回全量。所以续读只能靠
    /// 时间戳去重，不能指望它只给新增的部分。（同一个 scope 还有个 r. 87622922：
    /// `.reverse` 不生效，顺序也只能自己排。）
    ///
    /// **基线在第一次查询时定**：早于「用户第一次打开控制台」的条目不要——与 fd 那条
    /// 链路对称（那条也是挂上才开始收）。之后跨查询保留，于是两次查询之间那段捞得回来。
    private var lastDate: Date?

    // MARK: - 查询

    /// 查一次。幂等——正在查的时候再调，直接忽略。
    func refresh() {
        guard #available(iOS 15.0, *) else { return }
        guard !isRefreshing else { return }

        isRefreshing = true
        onStateChange?()

        queryQueue.async { [weak self] in
            guard let self = self else { return }
            let started = Date()
            let lines = self.query()
            let elapsed = Date().timeIntervalSince(started)

            // 结果先交给 store（它自己有锁），再把状态切回来是主线程的事
            if !lines.isEmpty { self.onLines?(lines) }

            DispatchQueue.main.async {
                self.lastDuration = elapsed
                self.isRefreshing = false
                self.onStateChange?()
            }
        }
    }

    @available(iOS 15.0, *)
    private func query() -> [ConsoleLine] {
        let last = lastDate ?? Date()
        lastDate = last

        guard let store = try? OSLogStore(scope: .currentProcessIdentifier),
              let entries = try? store.getEntries(at: store.position(date: last)) else {
            return []
        }

        var lines: [ConsoleLine] = []
        for entry in entries {
            guard let log = entry as? OSLogEntryLog else { continue }
            guard log.subsystem == subsystem || (includesEmptySubsystem && log.subsystem.isEmpty) else { continue }

            // position 不生效，全量回来，这一句才是真正的「续读」
            guard entry.date > last else { continue }

            lines.append(
                ConsoleLine(
                    date: entry.date,
                    source: .unifiedLog,
                    text: entry.composedMessage,
                    // undefined(0) 会映射成 nil ——「没记级别」就该是 nil
                    level: ConsoleLine.Level(rawValue: log.level.rawValue),
                    subsystem: log.subsystem,
                    category: log.category
                )
            )
        }

        guard !lines.isEmpty else { return [] }

        lastDate = lines.map(\.date).max() ?? last
        // 顺序自己排：`.reverse` 那个 option 在这个 scope 上不生效
        return lines.sorted { $0.date < $1.date }
    }
}
