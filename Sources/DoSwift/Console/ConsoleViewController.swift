//
//  ConsoleViewController.swift
//  DoSwift
//

import UIKit

/// 控制台。
///
/// 一屏里同时接着**两条链路**（见 `ConsoleLine.Source`），用底部那排按钮加导航栏的设置
/// 就够了，不需要编辑态：
///
/// - **暂停**：日志是流，一边来一边看是看不了的。暂停 = 冻结缓冲（不是停止刷新，
///   见 `ConsoleStore.isPaused`）。
/// - **清空 / 导出**：日志不是集合，逐条删没有意义——要整片清掉，或者整片带走。
///   所以这里刻意**没有**多选与侧滑删除（UserDefaults 那页有，是因为那里的项是数据）。
/// - **设置**：筛哪几条链路，是这一页唯一需要「记住」的东西。
///
/// 倒序显示（最新在最上面）：日志一直在来，跟用户抢滚动条是打不完的架。
final class ConsoleViewController: SectionTableViewController {

    // MARK: - State

    /// 与 `sections` 同形状的原始行：`sections` 里是渲染用的 `Row`，不带数据，
    /// 而「点进去看全文」要的是那一行本身。
    private var lines: [ConsoleLine] = []

    // MARK: - Views

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search lines"
        return controller
    }()

    private lazy var settingItem = UIBarButtonItem(
        image: UIImage(systemName: "gear"),
        style: .plain,
        target: self,
        action: #selector(showSettings)
    )

    // 底部操作条一律用图标：四个文字按钮在 375pt 宽上会挤。
    // 四个符号都核对过是 2019 年度（iOS 13.0）：pause / play.fill / arrow.clockwise /
    // trash / square.and.arrow.up（`name_availability.plist`）。
    private lazy var pauseItem = UIBarButtonItem(
        image: UIImage(systemName: "pause"),
        style: .plain,
        target: self,
        action: #selector(togglePause)
    )

    /// 统一日志那条链路是**按需**的：一次查询恒定约 1 秒，不能自动重复
    private lazy var unifiedLogItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.clockwise"),
        style: .plain,
        target: self,
        action: #selector(refreshUnifiedLog)
    )

    private lazy var clearItem = UIBarButtonItem(
        image: UIImage(systemName: "trash"),
        style: .plain,
        target: self,
        action: #selector(clear)
    )

    private lazy var exportItem = UIBarButtonItem(
        image: UIImage(systemName: "square.and.arrow.up"),
        style: .plain,
        target: self,
        action: #selector(export)
    )

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Console"

        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = settingItem

        // 这一页的操作条常驻（UserDefaults 那页只在编辑态露出来）
        navigationController?.setToolbarHidden(false, animated: false)

        // 用构造器而不是 `.flexibleSpace()`：那个静态方法是 iOS 14+，这条老写法 iOS 2 就有
        let spacer = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
        toolbarItems = [
            spacer(), unifiedLogItem, spacer(), pauseItem, spacer(), clearItem, spacer(), exportItem, spacer(),
        ]

        // 日志是别的线程推进来的，页面只是它的一个视图
        ConsoleStore.shared.onChange = { [weak self] in
            self?.reloadSections()
        }
        // 查询是~1 秒的事，按钮要在这一秒里变成「查询中」
        ConsoleStore.shared.unifiedLog.onStateChange = { [weak self] in
            self?.updateToolbarItems()
        }

        reloadSections()
    }

    /// 操作条是本页的：压了设置页会把它收掉，回到这一页要还回来。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(false, animated: animated)
    }

    /// 关闭。基类默认 `dismiss(animated:)`，但这条 nav 就是**窗口的 root**、没有任何 presenter，
    /// 所以在这里换成收起自己的窗口。
    override func close() {
        ConsolePlugin.shared.hide()
    }

    /// 退回初始态。由 `ConsolePlugin.show()` 每次调一次——窗口是复用的，
    /// 重开时不该还停在上次的搜索结果里。
    func refresh() {
        searchController.isActive = false
        view.endEditing(true)
        reloadSections()
    }

    // MARK: - Content

    private func reloadSections() {
        lines = ConsoleStore.shared.visibleLines()

        // 一行一段太碎，整页一段：日志的顺序本身就是信息，分组只会把它切断
        sections = [
            Section(footer: statusText, rows: lines.map { line in
                Row(
                    cellClass: SelectorCell.self,
                    onTrigger: { [weak self] _ in
                        self?.showDetail(line)
                    }
                ) { cell in
                    // 正文与元信息都压成一行：完整内容点进去看。行高整齐，一屏能看十几条。
                    // 标题用 `rowTitle`（换行折成一整行）——统一日志里带换行的消息
                    // 直接铺 `text` 的话，列表只显示得出第一行
                    cell.titleNumberOfLines = 1
                    cell.detailNumberOfLines = 1
                    cell.update(title: line.rowTitle, detail: line.metaText)
                }
            })
        ]

        updateToolbarItems()
    }

    /// 底部按钮的状态：暂停图标、有没有东西可清/可导、统一日志在不在查。
    private func updateToolbarItems() {
        let store = ConsoleStore.shared

        pauseItem.image = UIImage(systemName: store.isPaused ? "play.fill" : "pause")
        pauseItem.accessibilityLabel = store.isPaused ? "Resume" : "Pause"

        clearItem.isEnabled = store.capturedCount > 0
        exportItem.isEnabled = store.capturedCount > 0

        let refreshing = store.unifiedLog.isRefreshing
        unifiedLogItem.isEnabled = !refreshing && ConsoleUnifiedLog.isAvailable
        unifiedLogItem.accessibilityLabel = refreshing ? "Reading Unified Log" : "Read Unified Log"
    }

    /// 段脚注就是状态栏：抓到多少、显示多少、有没有在暂停、统一日志那边什么情况。
    ///
    /// 顺手把「上一次查询花了多久」写出来：一次约 1 秒这件事得让人看见，
    /// 否则「为什么要我手动点」就成了一个说不清的设计。
    private var statusText: String {
        let store = ConsoleStore.shared
        var parts = ["\(lines.count) of \(store.capturedCount) lines"]

        if store.isPaused { parts.append("paused") }

        if !ConsoleUnifiedLog.isAvailable {
            parts.append("Unified Log needs iOS 15")
        } else if store.unifiedLog.isRefreshing {
            parts.append("reading unified log…")
        } else if store.unifiedLog.lastDuration > 0 {
            parts.append(String(format: "unified log read in %.1fs", store.unifiedLog.lastDuration))
        }

        return parts.joined(separator: " · ")
    }

    // MARK: - Detail

    private func showDetail(_ line: ConsoleLine) {
        // 全文在这一步才拼：列表是滚动时逐行拼一次，详情页是用户明确要看的这一次
        let detail = PlainTextViewController(title: line.timeText, text: line.fullText)
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - Actions

    @objc private func showSettings() {
        navigationController?.pushViewController(ConsoleSettingViewController(), animated: true)
    }

    @objc private func togglePause() {
        ConsoleStore.shared.isPaused.toggle()
    }

    /// 统一日志那条链路查一次。
    ///
    /// 之所以要人点、而不是开着自动刷：一次查询实测恒定约 1 秒（`ConsoleUnifiedLog`
    /// 文件头有完整数据），定时跑等于永久占住一个核，换来的只是「不用点一下」。
    @objc private func refreshUnifiedLog() {
        ConsoleStore.shared.unifiedLog.refresh()
    }

    /// 清空。**要确认**：缓冲是这些日志的唯一一份，清掉就没了；
    /// 而且手指离底部操作条本来就近。要整片没了，值得多问一句。
    @objc private func clear() {
        let count = ConsoleStore.shared.capturedCount
        guard count > 0 else { return }

        let alert = UIAlertController(
            title: nil,
            message: "Clear \(count) line\(count > 1 ? "s" : "")?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            ConsoleStore.shared.clear()
        })
        present(alert, animated: true)
    }

    /// 导出走系统分享：日志最常见的去处是粘到别处去比对，
    /// 分享单里本来就有「拷贝」「存储到文件」这些出口，不必自己造。
    @objc private func export() {
        let text = ConsoleStore.shared.exportText()
        guard !text.isEmpty else { return }

        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        // iPad 上不给锚点会崩；这里锚在触发它的那颗按钮上
        activity.popoverPresentationController?.barButtonItem = exportItem
        present(activity, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension ConsoleViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        // 只写筛选状态：`ConsoleStore` 自己会通知刷新。
        // 页面不持有一份自己的关键字——那样就有两个「当前在搜什么」了。
        ConsoleStore.shared.filter.keyword = searchController.searchBar.text ?? ""
    }
}
