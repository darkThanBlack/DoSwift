//
//  SectionTableViewController.swift
//  DoSwift
//

import UIKit

/// 分组表的纯 UI 基类：**只管一张分组表长什么样，不管表里放什么**。
///
/// 子类只提供两样东西：`sections`（哪几段、每段几行、每行用哪种 cell 怎么填），
/// 以及各行 `onTrigger` 里要做的动作。`UITableViewDataSource` / `Delegate` 那一整套
/// ——注册、复用、表头表尾、事件转发——都在基类里，子类一行都不用写。
///
/// **事件只有一条路**：cell 发出 `trigger` → 基类接住（代理）→ 转给那一行的
/// `onTrigger`。所以这里没有 `didSelectRowAt`：整行被点只是 cell 可能发出的一种事件，
/// 让 cell 自己发，往后某一行多出长按、侧滑之类的事件时，这条链路一个字都不用改。
class SectionTableViewController: UIViewController, SectionCellDelegate {

    // MARK: - Model

    /// 一行：用哪种 cell、怎么把它填好、被「动了」之后做什么。
    ///
    /// `cellClass` 与两个闭包的类型由**同一个** `C` 绑定，于是子类侧是类型安全的
    /// （闭包参数就是 `ToggleCell`，读它的 `isOn` 不用强转），而唯一那次强转
    /// 被关在这一层里——基类只会把按 `cellClass` 取出来的 cell 递进去。
    struct Row {

        let cellClass: UITableViewCell.Type

        private let configureBox: (UITableViewCell) -> Void
        private let triggerBox: (UITableViewCell) -> Void

        init<C: UITableViewCell>(
            cellClass: C.Type,
            onTrigger: ((C) -> Void)? = nil,
            configure: @escaping (C) -> Void
        ) {
            self.cellClass = cellClass
            self.configureBox = { cell in
                guard let cell = cell as? C else { return }
                configure(cell)
            }
            self.triggerBox = { cell in
                guard let cell = cell as? C else { return }
                onTrigger?(cell)
            }
        }

        func configure(_ cell: UITableViewCell) {
            configureBox(cell)
        }

        /// 这一行的 cell 报上事件了。没给 `onTrigger` 的行什么都不做。
        func trigger(_ cell: UITableViewCell) {
            triggerBox(cell)
        }
    }

    /// 一段：可选的段标题 + 可选的段脚注 + 行
    struct Section {

        var title: String?
        var footer: String?
        var rows: [Row]

        init(title: String? = nil, footer: String? = nil, rows: [Row]) {
            self.title = title
            self.footer = footer
            self.rows = rows
        }
    }

    // MARK: - Content

    /// 表的内容。子类赋值即可，基类负责注册与刷新。
    var sections: [Section] = [] {
        didSet {
            registerCellClasses()
            tableView.reloadData()
        }
    }

    /// 已经注册过的 reuse id。同一个类只注册一次——`reloadData` 会反复走 `didSet`，
    /// 每次都把几十行重新注册一遍没有意义。
    private var registeredIdentifiers: Set<String> = []

    // MARK: - Views

    lazy var tableView: UITableView = {
        // .insetGrouped：分组卡片（白底 + 圆角 + 内缩）是**系统画的**，一个词换掉整页观感
        // （`UITableView.h:27`：grouped sections are inset with rounded corners，iOS 13 起）。
        // 卡片内缩之后，cell 内容与分隔线都改成相对卡片定位，下面那两处 16 仍然互相对齐。
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self

        // 这里放的都是「一屏看完」的检查面板，弹跳只会让人以为下面还有东西
        tableView.bounces = false

        // 行高由 cell 自己的约束算出来，所以要给一个真实的估算值
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56

        // 表头表尾与 cell 同待遇：按类注册、按 id 复用、高度 self sizing
        // （估算值不设，用系统默认）
        tableView.register(
            SectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: SectionHeaderView.self)
        )
        tableView.register(
            SectionFooterView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: SectionFooterView.self)
        )

        // 与 cell 内容的 16pt 左右留白对齐
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        return tableView
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        // 用这张表的都是被 present 出来的检查面板，关法一样，所以默认就把关闭按钮给上。
        // 要换关闭动作就覆盖 `close()`，要换成别的按钮就自己重设 `leftBarButtonItem`。
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )

        // 用约束而不是 frame：表跟着 view 走，旋转 / 分屏都不用自己再算一遍
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Actions

    /// 关闭自己。默认 `dismiss(animated:)`。
    @objc func close() {
        dismiss(animated: true)
    }

    // MARK: - Register

    private func registerCellClasses() {
        for row in sections.flatMap(\.rows) {
            let identifier = String(describing: row.cellClass)
            guard registeredIdentifiers.insert(identifier).inserted else { continue }
            tableView.register(row.cellClass, forCellReuseIdentifier: identifier)
        }
    }

    // MARK: - SectionCellDelegate

    /// 某一格的 cell 报上事件了，转给那一行。
    ///
    /// cell 只知道「自己被动了」，不知道自己是第几行；行只会渲染、不知道是哪种 cell
    /// ——`indexPath` 正好是这两者之间唯一的桥。
    func sectionCellDidTrigger(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        // 编辑态里高亮**就是**「已选中」，收掉它等于把多选废掉（`deselectRow` 会一并
        // 把这一行从 `indexPathsForSelectedRows` 里摘掉）——所以那一档交给系统。
        if !tableView.isEditing {
            // 没有 `didSelectRowAt`，系统的选中就没人收尾了：异步让它灭掉，
            // 时序与系统一致（先亮后灭），也不会把 `onTrigger` 里要弹出的界面盖住。
            // 下标在执行时才重算：`onTrigger` 里可能已经刷过表，捕获旧下标没有意义。
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let indexPath = self.tableView.indexPath(for: cell) else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }

        sections[indexPath.section].rows[indexPath.row].trigger(cell)
    }
}

// MARK: - UITableViewDataSource

extension SectionTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: row.cellClass),
            for: indexPath
        )
        row.configure(cell)

        // 会发事件的 cell 一律把事件报到这里，子类不必自己接
        (cell as? SectionCell)?.sectionDelegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SectionTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section].title else { return nil }

        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: SectionHeaderView.self)
        ) as? SectionHeaderView
        header?.titleLabel.text = title
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let title = sections[section].footer else { return nil }

        let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: SectionFooterView.self)
        ) as? SectionFooterView
        footer?.titleLabel.text = title
        return footer
    }

    /// 高度交给 self sizing：表头表尾视图自己的约束说了算。
    /// 没有标题 / 脚注的那一段压成 0，不留空隙。
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].title != nil ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        sections[section].footer != nil ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
    }
}
