//
//  ConsoleSettingViewController.swift
//  DoSwift
//

import UIKit

/// 控制台的设置页。
///
/// 只做一件事：**把每个开关的写操作导向 `ConsoleStore.filter`**。页面自己不缓存状态，
/// 于是不可能出现「界面显示开、列表按关筛」这种两份状态打架的情况。
final class ConsoleSettingViewController: SectionTableViewController {

    // MARK: - Model

    /// 一个开关项。顺带实现 `ToggleCellDataSource`——开关行要的三样正好都在它身上。
    private struct Item: ToggleCellDataSource {

        enum Kind {
            case source(ConsoleLine.Source)
            case emptySubsystem
        }

        let title: String
        let detail: String
        let kind: Kind

        var isOn: Bool {
            switch kind {
            case .source(let source):
                return ConsoleStore.shared.filter.sources.contains(source)
            case .emptySubsystem:
                return ConsoleStore.shared.filter.includesEmptySubsystem
            }
        }
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"

        // 基类默认给的是「关闭」按钮，动作是 `dismiss(animated:)`。这一页是**压进同一条
        // nav** 的，那条 nav 又是窗口的 root、没有 presenter——dismiss 什么都不会发生，
        // 按钮就成了一个死胡同。收掉它，UIKit 会自己摆上标准的返回箭头，
        // 连同左滑返回手势一起回来。
        navigationItem.leftBarButtonItem = nil

        // 底部操作条属于上一页（暂停/清空/导出），在设置页上摆着只会让人以为能点
        navigationController?.setToolbarHidden(true, animated: false)

        reloadSections()
    }

    // MARK: - Content

    private func reloadSections() {
        // iOS 15 之前统一日志那条路根本不存在，那一行开关摆着只会误导
        let sources = ConsoleLine.Source.allCases.filter {
            $0 != .unifiedLog || ConsoleUnifiedLog.isAvailable
        }

        var sections: [Section] = [
            Section(
                title: "Sources",
                footer: "Lines are tagged with the link they came from. "
                      + "Both fd links are received by one pipe tee, and are restored when the app exits.",
                rows: sources.map { source in
                    makeRow(Item(title: source.title, detail: source.detail, kind: .source(source)))
                }
            )
        ]

        if ConsoleUnifiedLog.isAvailable {
            sections.append(
                Section(
                    title: "Unified Log",
                    footer: "Read back through OSLogStore, current process only, iOS 15 or later. "
                          + "One read costs about a second regardless of how much is there, "
                          + "so it runs when you open the page and whenever you tap the button — "
                          + "never on a timer. "
                          + "Interpolated values are private by default: only what was logged with "
                          + "`privacy: .public` (and numbers) can be read, everything else is <private>.",
                    rows: [
                        makeRow(Item(
                            title: "No Subsystem",
                            detail: "A bare `Logger()` has an empty subsystem — "
                                  + "could be yours, could be a framework's",
                            kind: .emptySubsystem
                        ))
                    ]
                )
            )
        } else {
            sections.append(
                Section(title: "Unified Log", footer: "Unavailable on this system.", rows: [])
            )
        }

        self.sections = sections
    }

    /// 一项 → 一行。事件写在这里而不是 `didSelectRowAt`：**一行自己知道自己是谁**，
    /// 闭包直接捕获 `item`，不必靠 `indexPath` 反查回去。
    private func makeRow(_ item: Item) -> Row {
        Row(
            cellClass: ToggleCell.self,
            onTrigger: { [weak self] cell in
                // 事件不带值，值此刻就在 cell 上
                self?.update(item.kind, isOn: cell.isOn)
            }
        ) { cell in
            cell.update(item)
        }
    }

    // MARK: - Write

    /// 改筛选的唯一出口。改完不自己刷表——`ConsoleStore` 会通知，
    /// 本页和列表页读到的是同一份状态。
    private func update(_ kind: Item.Kind, isOn: Bool) {
        switch kind {
        case .source(let source):
            if isOn {
                ConsoleStore.shared.filter.sources.insert(source)
            } else {
                ConsoleStore.shared.filter.sources.remove(source)
            }
        case .emptySubsystem:
            ConsoleStore.shared.filter.includesEmptySubsystem = isOn
        }
    }
}
