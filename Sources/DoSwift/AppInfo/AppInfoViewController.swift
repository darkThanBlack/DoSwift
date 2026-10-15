//
//  AppInfoViewController.swift
//  DoSwift
//

import UIKit

/// 「App 信息」页。
///
/// 一屏看完的检查面板。它自己不做任何取值——数据全在 `AppInfo` 里，这里只做三件事：
/// 开页时让它 reload 一次、把值变成一行行 cell、点一下复制。
///
/// 交互两种：**点任意一行复制该行的值**；导航栏「复制 JSON」把整页序列化成 JSON 进剪贴板
/// （贴 issue 用，不必为此再开一个页面）。
final class AppInfoViewController: SectionTableViewController {

    // MARK: - State

    /// 宿主登记的字段，接在内建四组之后。由 `AppInfoPlugin.setCustomItems(_:)` 灌进来。
    var customRows: [DoSwiftAppInfoRow] = []

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "App 信息"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "复制 JSON",
            style: .plain,
            target: self,
            action: #selector(copyJSON)
        )
    }

    /// 由 `AppInfoPlugin.show()` 每次调一次。
    ///
    /// 窗口是复用的，上一次看到的 IP、权限、热状态全都过期了，所以要重取。
    /// 取值那一步在 `AppInfo.reload()` 里，这里只负责接上信号 + 重画。
    func refresh() {
        // **统一通知**：不关心是哪个字段变了，响一声就整表重拼。
        // `sections()` 是纯读，重拼的代价只有拼数组本身。
        AppInfo.shared.onChange = { [weak self] in self?.reload() }

        AppInfo.shared.reload()
        reload()
    }

    /// 关闭。基类默认 `dismiss(animated:)`，但这条 nav 是**窗口的 root**、没有 presenter，
    /// 所以换成收起自己的窗口（与 `UserDefaultsViewController` 同样的处理）。
    override func close() {
        AppInfoPlugin.shared.hide()
    }

    // MARK: - Content

    private func reload() {
        sections = displaySections.map { section in
            Section(title: section.title, rows: section.rows.map { row in
                Row(cellClass: KeyValueCell.self, onTrigger: { _ in
                    UIPasteboard.general.string = row.value
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) { cell in
                    cell.update(title: row.title, detail: row.value)
                    // 本页唯一一种交互是「点一下复制」，得让系统那圈高亮出来当反馈
                    // （`KeyValueCell` 默认 `.none`，那是给只读行留的）
                    cell.selectionStyle = .default
                }
            })
        }
    }

    /// 屏幕上和导出用的同一份数据：内建四组 + 宿主那组。
    private var displaySections: [DoSwiftAppInfoSection] {
        var data = AppInfo.shared.sections()
        if !customRows.isEmpty {
            data.append((title: "自定义", rows: customRows))
        }
        return data
    }

    // MARK: - 导出

    /// 整页序列化成 JSON 进剪贴板。
    ///
    /// 按组嵌套（`{"设备": {"机型": "…"}}`）、键排序：粘进 issue 里既读得懂，改动也能 diff。
    /// `JSONSerialization` 输出的是裸 UTF-8，中文键不做 `\u` 转义。
    ///
    /// **没有预览**是刻意的：这一页的全部用途就是把值带走，多一层页面只多一次点击。
    /// 复制成功与否靠那颗按钮的高亮和触感——与点行复制同一套反馈。
    @objc private func copyJSON() {
        var json: [String: [String: String]] = [:]
        for section in displaySections {
            // 逐条写而不是 `uniqueKeysWithValues`：宿主的 key 重名时后者会直接崩，
            // 而这里只是后写的盖掉先写的——面板不该因为一行数据把 App 弄挂
            var rows: [String: String] = [:]
            for row in section.rows {
                rows[row.title] = row.value
            }
            json[section.title] = rows
        }

        guard let data = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let text = String(data: data, encoding: .utf8)
        else { return }

        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
