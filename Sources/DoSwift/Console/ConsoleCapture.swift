//
//  ConsoleCapture.swift
//  DoSwift
//

import Foundation

/// 把进程的标准输出 / 标准错误接到自己的管道上：**边转发回原处，边留一份**。
///
/// 用到的系统调用只有 `pipe` / `dup` / `dup2` / `read` / `write`，全在 libc 这一层，
/// 与跑在 mac、模拟器还是真机无关（Darwin 就是 Darwin；两个 SDK 里 `sys/fcntl.h:292`
/// 的 `F_SETNOSIGPIPE` 都是 73，`sys/syslimits.h:104` 的 `PIPE_BUF` 都是 512）。
///
/// 三件实测出来的事实决定了这份实现长什么样：
///
/// 1. **`print` 落 fd 1，`NSLog` 落 fd 2。** 把这两个号都改指管道，两者就一起进来了
///    ——它们本来就是同一根管道的两个入口，不需要分别 hook 谁。
/// 2. **stdout 指向管道（不是 tty）时 stdio 走全缓冲。** 实测 1 秒内一个字节都收不到，
///    日志页会一卡一卡地跳。所以接管期间改成行缓冲，代价见 `attach`。
/// 3. **往读端已关闭的管道写会打死进程。** 实测默认动作是信号 13，不是「写失败」。
///    Xcode 断开、真机点图标启动都会造成这种局面，而我们每次都在往回写。必须关掉。
///
/// ## 一个做不到的事：字节流里没有「记录」
///
/// 系统是有记录的，边界是 **API 调用**——实测 `log.notice("A\nB\nC")` 在统一日志里是
/// **一条**记录，换行在那个记录里面；Xcode 15 的控制台显示的就是这个流，所以它能显示成
/// 一条。而 **fd 2 上这个边界已经没了**：libtrace 把同一条记录回显到 fd 2 时，
/// **只有第一行带 `日期 时间 名字[pid:tid]` 前缀**，后面几行是裸的
/// （实测：`OSLOG-A` 带前缀，`OSLOG-B` / `OSLOG-C` 不带）。
///
/// 也就是说，字节流里那三行和「业务自己 print 了三次」**完全无法区分**。
/// 这里做的续行合并是**在猜**，判据见 `deliver`，只覆盖 ObjC 老式多行 description；
/// libtrace 那条多行回显覆盖不到——而它只在挂调试器时才存在，那种场合 Xcode 自己的
/// 控制台显示得比这里准。
///
/// - Warning: `onLine` 是在**捕获队列**上回调的，别在那里碰 UI；
///   也**绝对不要**在回调里 `print` —— 那条输出会重新写进管道，绕成一个环。
final class ConsoleCapture {

    static let shared = ConsoleCapture()
    private init() {}

    /// 收到一整行时回调（后台队列）
    var onLine: ((ConsoleLine) -> Void)?

    /// 收到一条**续行**时回调（后台队列）。
    ///
    /// 续行 = 属于上一条记录、不是新的一条。见 `isContinuation`。
    var onContinuation: ((ConsoleLine.Source, String) -> Void)?

    private let queue = DispatchQueue(label: "com.doswift.console.capture")

    /// 一次 `read` 的缓冲大小。管道容量实测约 64KB，4096 足够快地排空。
    private let chunkSize = 4096

    /// 一行最长的字节数。没有换行的输出（进度条、连续打点）会让待处理缓冲无限增长，
    /// 超过就当作一行放出去——丢掉换行边界，好过把宿主 App 的内存吃掉。
    private let maxPendingBytes = 64 * 1024

    /// 一条被接管的流。
    ///
    /// 两条流**各占一根管道**，不合并：合成一根之后就再也分不出哪行是 `print`、
    /// 哪行是 `NSLog` 了——而「来源」正是设置页要筛的东西。
    private final class Stream {

        /// 原始的 fd 号（`STDOUT_FILENO` / `STDERR_FILENO`）
        let fd: Int32

        let source: ConsoleLine.Source

        /// 接管之前 dup 出来的原 fd，tee 回去时写的就是它
        let original: Int32

        let readEnd: Int32

        /// 还没凑齐一整行的尾巴
        var pending = Data()

        /// 还差几层括号才收尾。> 0 表示「正处于一条多行输出的中间」，见 `deliver`
        var openBrackets = 0

        /// 当前这条记录已经并进多少行续行
        var mergedLines = 0

        func resetContinuation() {
            openBrackets = 0
            mergedLines = 0
        }

        /// 上一条交付出去的时刻。用来判断「这是新的一轮输出」还是「上一条还没写完」
        var lastDelivery = Date.distantPast

        var dispatchSource: DispatchSourceRead?

        init(fd: Int32, source: ConsoleLine.Source, original: Int32, readEnd: Int32) {
            self.fd = fd
            self.source = source
            self.original = original
            self.readEnd = readEnd
        }
    }

    private var streams: [Stream] = []

    private(set) var isRunning = false

    // MARK: - 开关

    func start() {
        guard !isRunning else { return }
        isRunning = true

        attach(fd: STDOUT_FILENO, source: .standardOutput)
        attach(fd: STDERR_FILENO, source: .standardError)
    }

    /// - Warning: 只能在**捕获队列之外**调（内部有 `queue.sync` 收尾）。
    ///   目前唯一的调用点是工具的开关，都在主线程。
    func stop() {
        guard isRunning else { return }
        isRunning = false

        // 顺序不能反。

        // 1) 先把 stdio 的缓冲逼出去：不然最后几行还堵在里面，永远进不了管道
        fflush(stdout)
        fflush(stderr)

        // 缓冲策略换回全缓冲。行缓冲是接管期间的临时状态，不该留给宿主 App
        setvbuf(stdout, nil, _IOFBF, Int(BUFSIZ))
        setvbuf(stderr, nil, _IOFBF, Int(BUFSIZ))

        // 2) 把 fd 还给原来的目标。这一步关掉了管道的写端
        for stream in streams {
            guard stream.original >= 0 else { continue }
            dup2(stream.original, stream.fd)
            close(stream.original)
        }

        // 3) 管道里剩下的还得读出来，否则关工具时最后几行凭空消失。
        //    在捕获队列上同步做，免得和事件回调抢同一根管道
        queue.sync {
            for stream in streams {
                drain(stream.source)
                flushTail(of: stream)
            }
        }

        // 4) 关读端（`cancel` 的 handler 里 close）
        for stream in streams { stream.dispatchSource?.cancel() }
        streams.removeAll()
    }

    // MARK: - 接管

    private func attach(fd: Int32, source: ConsoleLine.Source) {
        var ends: [Int32] = [0, 0]
        guard pipe(&ends) == 0 else { return }
        let readEnd = ends[0]
        let writeEnd = ends[1]

        // 留住原来的 fd
        let original = dup(fd)

        // 关掉 SIGPIPE —— 这一句不是防御性编程，是必须的。
        //
        // 实测：往一个读端已关闭的管道写，默认动作是把**进程打死**（信号 13），
        // 而不是让 write 返回错误。Xcode 断开连接、真机从图标启动都会造成读端消失。
        // 关掉之后 write 只返回 EPIPE，进程活着。
        // 原 fd 也要设：tee 时写的正是它。
        _ = fcntl(writeEnd, F_SETNOSIGPIPE, 1)
        if original >= 0 { _ = fcntl(original, F_SETNOSIGPIPE, 1) }

        // 读端设成非阻塞。
        //
        // `DispatchSourceRead` 只保证「可读时叫你」，并不改 fd 的标志位。少了这一句，
        // 回调里那一圈「读到没有为止」的第二次 `read` 就会挂在空管道上——挂住的是
        // 捕获线程，等于整个日志链路停摆。
        _ = fcntl(readEnd, F_SETFL, O_NONBLOCK)

        // stdio 缓冲改成行缓冲。
        //
        // **代价说清楚**：这是对宿主 App 的全局副作用——此后它每一次 `print` 都会多一次
        // 写系统调用。所以只在用户第一次打开控制台时挂一次（`ConsoleStore` 里控制的），
        // 不是库一启动就挂。
        setvbuf(stdout, nil, _IOLBF, 0)
        setvbuf(stderr, nil, _IOLBF, 0)

        // 让这个号改指管道写端。此后 `print` / `NSLog` / 任何直接写这个号的，
        // 都进了管道——这就是它们能被一次抓完的原因。
        dup2(writeEnd, fd)

        // fd 已经指过去了，这个多余的写端引用要关掉，否则管道永远等不到 EOF
        close(writeEnd)

        let stream = Stream(fd: fd, source: source, original: original, readEnd: readEnd)
        let dispatchSource = DispatchSource.makeReadSource(fileDescriptor: readEnd, queue: queue)
        // 捕获 `self`（单例，无所谓）和枚举而不是 `stream`：`stream` 持有 source、
        // source 持有 handler，直接捕获就是一圈自己咬自己的引用
        dispatchSource.setEventHandler { [weak self] in
            self?.drain(source)
        }
        dispatchSource.setCancelHandler { close(readEnd) }
        stream.dispatchSource = dispatchSource
        streams.append(stream)
        dispatchSource.resume()
    }

    // MARK: - 读

    private func drain(_ source: ConsoleLine.Source) {
        guard let stream = streams.first(where: { $0.source == source }) else { return }

        var buffer = [UInt8](repeating: 0, count: chunkSize)
        while true {
            let count = read(stream.readEnd, &buffer, buffer.count)
            guard count > 0 else { break }   // 0 = EOF；非阻塞下的 -1 就是 EAGAIN，两种都该收手

            stream.pending.append(contentsOf: buffer[0..<count])
            emitLines(from: stream)

            // 没换行的超长输出：当成一行放掉，别让它无限长
            if stream.pending.count > maxPendingBytes { flushTail(of: stream) }
        }
    }

    /// 按换行切行，只把**完整行**交出去。
    ///
    /// 尾巴一律留到下一次读：管道是字节流，一次 `read` 可能只拿到一个多字节字符的
    /// 头一个字节。实测拿到 `E4` 之后立刻 `String(data:encoding:.utf8)` 得到 nil
    /// ——那个汉字整条丢掉。
    private func emitLines(from stream: Stream) {
        while let breakIndex = stream.pending.firstIndex(of: 0x0A) {
            let lineData = stream.pending[stream.pending.startIndex..<breakIndex]
            let resumeIndex = stream.pending.index(after: breakIndex)
            stream.pending.removeSubrange(stream.pending.startIndex..<resumeIndex)

            var text = String(decoding: lineData, as: UTF8.self)
            // `\r\n` 折掉剩下的那个 `\r`
            if text.hasSuffix("\r") { text.removeLast() }

            deliver(text, from: stream)
        }
    }

    // MARK: - 续行

    /// 两行之间的间隔超过这个值，就当成「新的一轮输出」，不把下一行并到上一行。
    ///
    /// 防的是这种误判：某条日志碰巧以 `(` 结尾，半分钟后才来下一条无关的日志，
    /// 那条就会被粘上去。多行输出是一次 description 一口气吐出来的，间隔以微秒计。
    private let continuationGap: TimeInterval = 0.5

    /// 一条记录最多并多少行续行。
    ///
    /// 防的是判据本身可能错判的那种情况：某条**普通日志**恰好以 `(` 结尾，而后面是持续
    /// 不断的输出，它就会一直把后面的行吞进来。到了上限就认栽、另起一条——
    /// 最多吞掉这么多行，不会把整屏日志并成一行。
    private let maxContinuationLines = 30

    /// 交付一行——决定它是**新的一条**还是**上一条的续行**。
    ///
    /// 判据只看内容形状，不看是哪个流：
    /// **上一行以 `(` / `{` / `[` 结尾 → 接下来的行都属于它，直到有一行以 `)` / `}` / `]` 开头。**
    ///
    /// 为什么是这个判据：ObjC 老式多行 description（`NSLog("%@", array)` 打出来的那种）
    /// 长这样——
    ///
    /// ```
    /// 2026-10-14 19:18:21.416 App[8695:3906990] (
    ///     alpha,
    ///     beta,
    ///     gamma
    /// )
    /// ```
    ///
    /// 它是**一条记录**，但在字节流里就是 5 个换行。不认出来的话，列表里会出现一行孤零零的
    /// `(` 和一行 `)`。
    ///
    /// 不用「行首有没有 `日期 时间` 头」来判：那个头只有 NSLog 和 libtrace 才有，
    /// 业务自己 `fputs(stderr)` 的裸行没有——那样判的话，一条裸行会粘到上一条 NSLog 后面。
    /// 按括号判是自限的：普通日志行不会以 `(` 结尾。
    private func deliver(_ text: String, from stream: Stream) {
        let now = Date()

        // 隔得太久 = 新的一轮，把「还在括号里」这件事清掉
        if now.timeIntervalSince(stream.lastDelivery) > continuationGap {
            stream.resetContinuation()
        }
        stream.lastDelivery = now

        if stream.openBrackets > 0 {
            // 正在一条多行输出中间：先按「本行是不是收尾」调整层数，再交出去
            if Self.startsWithCloser(text) { stream.openBrackets -= 1 }
            stream.mergedLines += 1

            if stream.mergedLines <= maxContinuationLines {
                onContinuation?(stream.source, text)
                return
            }
            // 并得太多了，多半本来就不是一条多行输出。认栽，把这一行当成新的一条
            stream.resetContinuation()
        }

        if Self.endsWithOpener(text) {
            stream.openBrackets += 1
            stream.mergedLines = 0
        }
        onLine?(ConsoleLine(date: now, source: stream.source, text: text))
    }

    /// 最后一个非空白字符是不是开括号
    private static func endsWithOpener(_ text: String) -> Bool {
        guard let last = text.last(where: { !$0.isWhitespace }) else { return false }
        return last == "(" || last == "{" || last == "["
    }

    /// 第一个非空白字符是不是闭括号
    private static func startsWithCloser(_ text: String) -> Bool {
        guard let first = text.first(where: { !$0.isWhitespace }) else { return false }
        return first == ")" || first == "}" || first == "]"
    }

    /// 把没以换行结尾的残留放出来。
    ///
    /// 解码用 `String(decoding:as:)` 而不是 `String(data:encoding:)`：前者**有损但永不返回
    /// nil**，真遇上被劈开的多字节字符会替换成 U+FFFD。调试工具宁可显示一个 �，
    /// 也不能凭空少一行。
    private func flushTail(of stream: Stream) {
        guard !stream.pending.isEmpty else { return }

        let text = String(decoding: stream.pending, as: UTF8.self)
        stream.pending.removeAll()
        deliver(text, from: stream)
    }
}
