//
//  HierarchySettingViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/10.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构工具的配置页。
///
/// 只做一件事：**把每个开关的写操作导向 `HierarchyPlugin.config`**。值怎么存、存哪
/// 由 `HierarchyConfig` 负责，页面自己不缓存任何状态——于是不可能出现
/// 「界面显示开、工具按关执行」这种两份状态打架的情况。
///
/// 每次改动都即时落盘（`persistConfig()`）并回调 `onChange`，所以没有「保存」按钮，
/// 也不会出现改完忘了确认就退出。
class HierarchySettingViewController: UIViewController {

    /// 任一项变化后回调，让主界面立刻反映（关掉标线就收线、关掉取色就收放大镜）
    var onChange: (() -> Void)?

    // MARK: - Model

    private struct Row {

        enum Kind {
            case toggle(WritableKeyPath<HierarchyConfig, Bool>)
            case selector(WritableKeyPath<HierarchyConfig, HierarchyConfig.Visibility>)
        }

        let title: String
        let detail: String
        let kind: Kind
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    /// 三个分组固定：取色器 / 标尺 / 视图结构。
    ///
    /// 每一组都是「功能总开关」+「它的浮层什么时候出现」两行——总开关管「要不要」，
    /// 显隐管「什么时候看得见」，两者不重复。
    private let sections: [Section] = [
        Section(title: "Color Picker", rows: [
            Row(title: "Enabled",
                detail: "Pixel color readout in the panel, plus the loupe",
                kind: .toggle(\.isColorPickEnabled)),
            Row(title: "Loupe",
                detail: "When the magnifier appears",
                kind: .selector(\.loupeVisibility)),
        ]),
        Section(title: "Align Ruler", rows: [
            Row(title: "Enabled",
                detail: "Distances to the four edges in the panel, plus the cross lines",
                kind: .toggle(\.isAlignRulerEnabled)),
            Row(title: "Cross Lines",
                detail: "When the ruler lines appear",
                kind: .selector(\.rulerVisibility)),
        ]),
        Section(title: "View Hierarchy", rows: [
            Row(title: "Ignore Private Classes",
                detail: "Skip views whose class name starts with an underscore",
                kind: .toggle(\.isIgnorePrivateClass)),
        ]),
    ]

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        // 不 register：行要用到 detailTextLabel，必须自己用 .subtitle 建
        return tableView
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissSetting)
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    // MARK: - Write

    /// 改配置的唯一出口：改 → 落盘 → 通知主界面。
    ///
    /// 三者绑在一起，就不存在「改了没存」或「存了没刷新」这种漏一步的写法。
    private func update(_ mutate: (inout HierarchyConfig) -> Void) {
        var config = HierarchyPlugin.shared.config
        mutate(&config)

        HierarchyPlugin.shared.config = config
        HierarchyPlugin.shared.persistConfig()

        tableView.reloadData()
        onChange?()
    }

    // MARK: - Actions

    @objc private func dismissSetting() {
        dismiss(animated: true)
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        // 开关只带得动一个 Int，所以用「拍平后的行号」当 tag，
        // 而不是 IndexPath —— 否则还得把 section 也塞进 tag 里做位运算
        guard flatRows.indices.contains(sender.tag),
              case .toggle(let keyPath) = flatRows[sender.tag].kind else { return }

        update { $0[keyPath: keyPath] = sender.isOn }
    }

    private func row(at indexPath: IndexPath) -> Row? {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].rows.indices.contains(indexPath.row) else { return nil }
        return sections[indexPath.section].rows[indexPath.row]
    }

    private var flatRows: [Row] {
        sections.flatMap { $0.rows }
    }

    private func flatIndex(of indexPath: IndexPath) -> Int {
        var index = indexPath.row
        for section in 0..<indexPath.section {
            index += sections[section].rows.count
        }
        return index
    }
}

// MARK: - UITableViewDataSource

extension HierarchySettingViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // `dequeueReusableCell(withIdentifier:)` 已经返回 UITableViewCell?，不用再转
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        guard let row = row(at: indexPath) else { return cell }

        cell.textLabel?.text = row.title
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0

        switch row.kind {
        case .toggle(let keyPath):
            cell.detailTextLabel?.text = row.detail
            cell.selectionStyle = .none
            cell.accessoryType = .none

            let toggle = UISwitch()
            toggle.tag = flatIndex(of: indexPath)
            toggle.isOn = HierarchyPlugin.shared.config[keyPath: keyPath]
            toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle

        case .selector(let keyPath):
            // 选择行把「当前值」摆在副标题上，一眼能看到状态，比再写一遍说明有用
            cell.detailTextLabel?.text = HierarchyPlugin.shared.config[keyPath: keyPath].title
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension HierarchySettingViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let row = row(at: indexPath), case .selector(let keyPath) = row.kind else { return }

        let options = HierarchyConfig.Visibility.allCases
        let current = HierarchyPlugin.shared.config[keyPath: keyPath]

        hierarchy_showActionSheet(
            title: row.title,
            actions: options.map { $0.title },
            currentAction: current.title
        ) { [weak self] index in
            guard let self = self, options.indices.contains(index) else { return }
            self.update { $0[keyPath: keyPath] = options[index] }
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == sections.count - 1 else { return nil }
        return "Applied immediately and remembered in UserDefaults."
    }
}
