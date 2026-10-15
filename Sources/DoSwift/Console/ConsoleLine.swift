//
//  ConsoleLine.swift
//  DoSwift
//

import Foundation

/// 控制台里的一行。
///
/// 它来自**两条互不相干的链路**，模型得同时容得下：
///
/// - **fd 那条**（`print` 走 fd 1，`NSLog` 走 fd 2）：只有一段纯文本。系统没给级别、
///   也没给来源，就不该替它编一个。
/// - **统一日志那条**（`os_log` / `Logger`）：有级别、有 subsystem / category，
///   但 iOS 15 起才读得到，而且插值默认被系统掩成 `<private>`。
///
/// 所以除 `text` 外一律可选，**不给缺省值**——把 `level` 默认成 `.info`，就是把
/// 「不知道」谎报成「Info」。
struct ConsoleLine {

    /// 这一行是从哪条链路来的。同时充当设置页里的筛选项。
    enum Source: String, CaseIterable {

        case standardOutput
        case standardError
        case unifiedLog

        var title: String {
            switch self {
            case .standardOutput: return "Standard Output"
            case .standardError:  return "Standard Error"
            case .unifiedLog:     return "Unified Log"
            }
        }

        /// 说明里把那句「其实就是哪个 fd」写出来：调 iOS 的人多半记不住
        /// `print` 走 1、`NSLog` 走 2，而这正是这个工具全部依据的两条事实。
        var detail: String {
            switch self {
            case .standardOutput: return "print / fputs / FileHandle — fd 1"
            case .standardError:  return "NSLog — fd 2"
            case .unifiedLog:     return "os_log / Logger — readable since iOS 15"
            }
        }
    }

    /// 统一日志的级别。
    ///
    /// 原始值与 `OSLogEntryLogLevel` 对齐（`EntryLog.h`：undefined/debug/info/notice/error/fault），
    /// 免得两套编号来回换算。
    enum Level: Int, CaseIterable {
        case debug = 1
        case info = 2
        case notice = 3
        case error = 4
        case fault = 5

        var title: String {
            switch self {
            case .debug:  return "Debug"
            case .info:   return "Info"
            case .notice: return "Notice"
            case .error:  return "Error"
            case .fault:  return "Fault"
            }
        }
    }

    let date: Date
    let source: Source
    var text: String
    var level: Level?
    var subsystem: String?
    var category: String?

    /// 只到毫秒的时刻（`HH:mm:ss.SSS`）。
    ///
    /// **建行时就格式化，不是渲染时算。** `DateFormatter` 单次不便宜：2000 行每次刷表
    /// 都格式化一遍，实测 2.1 ms —— 而这一行的时间根本不会变。列表滚动时这一项是白付的。
    ///
    /// 详情页拿它当标题（比来源更能认出「是哪一行」）。
    let timeText: String

    init(
        date: Date,
        source: Source,
        text: String,
        level: Level? = nil,
        subsystem: String? = nil,
        category: String? = nil
    ) {
        self.date = date
        self.source = source
        self.text = text
        self.level = level
        self.subsystem = subsystem
        self.category = category
        self.timeText = ConsoleLine.format(date)
        self.rowTitle = text.contains("\n") ? ConsoleLine.flatten(text) : text
    }

    /// 折成一整行：空白（含换行）压成单个空格，再截到 300 字符。
    ///
    /// 先折行再截断没区别，但**截断位置按折行后的长度算**更好理解——列表本来显示的就是
    /// 折行后的样子。
    private static func flatten(_ text: String) -> String {
        let folded = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return String(folded.prefix(300))
    }

    // MARK: - 显示

    /// 行上带毫秒：日志的先后顺序常常就是全部线索，「同一秒内发生了什么」得看得出。
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// `DateFormatter` 不是线程安全的，而建行的有两条队列（捕获队列、统一日志查询队列）。
    /// 用一把锁把这一次格式化护住——比起每次刷表算 2000 遍，这点开销不值一提。
    private static let formatterLock = NSLock()

    private static func format(_ date: Date) -> String {
        formatterLock.lock()
        defer { formatterLock.unlock() }
        return timeFormatter.string(from: date)
    }

    /// 列表行的副标题：时间 · 级别 · 来源。
    ///
    /// 级别不是每条都有（打印语句没有），所以是「有就带上」而不是占位。
    var metaText: String {
        var parts = [timeText]
        if let level = level { parts.append(level.title) }
        parts.append(source.title)
        return parts.joined(separator: " · ")
    }

    /// 列表行**标题**用的单行文本。
    ///
    /// fd 那条链路不会用到它——那边一条记录已经是一行（多行输出会被并成一条，
    /// 见 `ConsoleCapture.deliver`）。**统一日志那条才需要**：一条 `OSLogEntry` 就是
    /// 一行，消息里自带换行时，列表只显示出第一行，后面几行白看不见。
    ///
    /// 折成一整行 + 截断，与 UserDefaults 浏览器那张表的 `summary` 同一套做法。
    /// 绝大多数行没有换行，那时直接指向原文（`String` 是值语义，不复制）。
    ///
    /// **改正文必须走 `setText`**：它是从 `text` 算出来的，散着写 `text` 会让两者不一致
    /// ——列表上就还是显示成断在 `(` 那里的老样子（这个坑真踩过一次）。
    private(set) var rowTitle: String

    // MARK: - 改正文

    /// 改正文的唯一入口：截断与折行一起做，`text` 与 `rowTitle` 不可能不同步。
    mutating func setText(_ newText: String, limit: Int) {
        // `utf8.count` 是 O(1) 且恒 >= 字符数：它没超就一定能原样留下，
        // 于是常见路径上不必对整行做一次 O(n) 的字符计数
        let needsTruncating = newText.utf8.count > limit && newText.count > limit
        text = needsTruncating ? String(newText.prefix(limit)) : newText
        rowTitle = text.contains("\n") ? ConsoleLine.flatten(text) : text
    }

    /// 并进一条续行（见 `ConsoleCapture.deliver`）
    mutating func appendContinuation(_ fragment: String, limit: Int) {
        setText(text + "\n" + fragment, limit: limit)
    }

    /// 详情页的全文：先把已知的元信息逐条列清楚，再原样铺开正文。
    ///
    /// 等宽 + 标签对齐，是为了「一眼扫到 Subsystem」；正文不加任何加工，
    /// 要看的就是它本来长什么样。
    var fullText: String {
        var rows = [
            "Time:      \(timeText)",
            "Source:    \(source.title) — \(source.detail)",
        ]
        if let level = level { rows.append("Level:     \(level.title)") }
        if let subsystem = subsystem, !subsystem.isEmpty { rows.append("Subsystem: \(subsystem)") }
        if let category = category, !category.isEmpty { rows.append("Category:  \(category)") }

        return rows.joined(separator: "\n") + "\n\n" + text
    }
}
