//
//  UserDefaultsViewController.swift
//  DoSwift
//

import UIKit

/// UserDefaults 浏览器。
///
/// 三种交互全部落在这一层（基类只提供表本身）：
/// - **搜索**：`UISearchController` 挂 `navigationItem`。原版（DoKit）是把手搓的 `UITextField`
///   塞进 `titleView`，那是 iOS 11 之前的做法，连清除按钮和取消按钮都要自己画。
/// - **多选 + 批量删**：`editButtonItem`（系统给的 Edit/Done 按钮）+ `allowsMultipleSelectionDuringEditing`
///   （系统画多选圈）+ 一个底部操作条。操作条系统没有成品件，但用的仍是系统按钮。
/// - **单删**：`trailingSwipeActionsConfigurationForRowAt`。
///
/// 本页只做三件事：把快照翻成分组、处理交互、把值页推出去。
final class UserDefaultsViewController: SectionTableViewController {

    // MARK: - State

    /// 当前显示的快照（已含搜索过滤）
    private var snapshot: UserDefaultsSnapshot = .capture()

    /// 与 `sections` 同形状的原始项：`sections` 里是渲染用的 `Row`，不带数据，
    /// 而删除要的是 key。两者由 `reloadSections()` 同序生成，下标一一对应。
    private var visibleItems: [[UserDefaultsSnapshot.Item]] = []

    /// 搜索关键字，空 = 不过滤
    private var keyword: String = ""

    // MARK: - Views

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        // 结果就在这张表里就地过滤，不需要盖住内容
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search by key"
        return controller
    }()

    private lazy var deleteItem = UIBarButtonItem(
        title: "Delete",
        style: .plain,
        target: self,
        action: #selector(deleteSelected)
    )

    private lazy var selectAllItem = UIBarButtonItem(
        title: "Select All",
        style: .plain,
        target: self,
        action: #selector(toggleSelectAll)
    )

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UserDefaults"

        // 列表可能有几百行，搜索框常驻比「上滑就藏起来」实用（基类 `bounces = false`，
        // 藏起来之后还得多滚回顶部才能露出来）
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = editButtonItem

        tableView.allowsMultipleSelectionDuringEditing = true
        navigationController?.setToolbarHidden(true, animated: false)

        reloadSections()
    }

    /// 关闭。基类默认 `dismiss(animated:)`，但这条 nav 就是**窗口的 root**、没有任何 presenter，
    /// 所以在这里换成收起自己的窗口。
    override func close() {
        UserDefaultsPlugin.shared.hide()
    }

    /// 退回初始态并重读一次数据。
    ///
    /// 由 `UserDefaultsPlugin.show()` 每次调一次：窗口是复用的，两次打开之间 UserDefaults
    /// 可能已经被别处改过；同时把搜索与编辑态收掉，免得重开看到的是上次的残局。
    func refresh() {
        setEditing(false, animated: false)
        searchController.isActive = false
        view.endEditing(true)

        snapshot = .capture()
        reloadSections()
    }

    // MARK: - Content

    private func reloadSections() {
        let filtered = snapshot.filtered(by: keyword)
        visibleItems = filtered.domains.map(\.items)

        sections = filtered.domains.map { domain in
            Section(title: domain.title, rows: domain.items.map { item in
                Row(
                    cellClass: SelectorCell.self,
                    onTrigger: { [weak self] _ in
                        // 编辑态里点行的语义是「选中」，但它和普通点击走的是**同一条**
                        // `setSelected` → trigger 链路（`SelectorCell` 发事件、基类路由），
                        // 少了这道闸就会一边勾选一边弹出详情页
                        guard let self = self, !self.isEditing else { return }
                        self.showDetail(item)
                    }
                ) { cell in
                    // 副标题单行：完整值点进去看，行高才整齐
                    cell.detailNumberOfLines = 1
                    cell.update(title: item.key, detail: item.summary)
                }
            })
        }
    }

    // MARK: - Detail

    private func showDetail(_ item: UserDefaultsSnapshot.Item) {
        // 全文在**推页面这一步**才拼：列表是滚动时逐行拼一次（`summary` 已经绕开了
        // Data 那个大头），详情页则是用户明确要看的这一次
        let detail = PlainTextViewController(title: item.key, text: item.fullText)
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - Delete

    /// 单删与批删汇到这里。
    ///
    /// 参数是**项**而不是 `indexPath`：删完会整表重建，下标立刻指向别的行了，只有 key 还认得。
    /// 删完重新 capture 而不是从内存里抠掉那一行：删的是**存储**，列表就该反映存储的真实状态
    /// ——比如删掉一个仍能从下层域解析出来的 key，它下一帧还会回来，这是事实，不该藏。
    private func delete(_ items: [UserDefaultsSnapshot.Item]) {
        items.forEach { UserDefaults.standard.removeObject(forKey: $0.key) }

        snapshot = .capture()
        reloadSections()

        // 整表重建不会补发选中/取消选中的回调，批量条上的计数得自己重算
        updateBatchItems()
    }

    private func item(at indexPath: IndexPath) -> UserDefaultsSnapshot.Item? {
        guard visibleItems.indices.contains(indexPath.section),
              visibleItems[indexPath.section].indices.contains(indexPath.row) else { return nil }
        return visibleItems[indexPath.section][indexPath.row]
    }

    // MARK: - Edit

    override func setEditing(_ editing: Bool, animated: Bool) {
        // 头文件要求 override 时先调 super（`UIViewController.h:401`）
        super.setEditing(editing, animated: animated)

        // `editButtonItem` 只切 VC 自己的状态，不会动我们自己持有的这张表
        tableView.setEditing(editing, animated: animated)

        // 用构造器而不是 `.flexibleSpace()`：那个静态方法是 iOS 14+，
        // 这条老写法 iOS 2 就有（部署目标是 13）
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = editing ? [selectAllItem, spacer, deleteItem] : []
        navigationController?.setToolbarHidden(!editing, animated: animated)

        updateBatchItems()
    }

    /// 批量条上两个按钮的状态跟着选中数走
    private func updateBatchItems() {
        let selected = tableView.indexPathsForSelectedRows?.count ?? 0
        let total = allIndexPaths.count

        deleteItem.isEnabled = selected > 0
        deleteItem.title = selected > 0 ? "Delete (\(selected))" : "Delete"

        selectAllItem.isEnabled = total > 0
        selectAllItem.title = (total > 0 && selected == total) ? "Deselect All" : "Select All"
    }

    private var allIndexPaths: [IndexPath] {
        sections.indices.flatMap { section in
            sections[section].rows.indices.map { IndexPath(row: $0, section: section) }
        }
    }

    /// 全选 / 取消全选。
    ///
    /// UIKit 没有「全选」这件控件——全 SDK 只有 `UIResponder.selectAll`，那是**文本编辑**语义
    /// （`UIResponder.h:42`）。所以只能逐行调系统的 `selectRow`；它只对**已存在的行**有效，
    /// 因此必须在 `sections` 赋值之后调用，这里的调用点都在那之后。
    @objc private func toggleSelectAll() {
        let all = allIndexPaths
        let selected = tableView.indexPathsForSelectedRows?.count ?? 0
        let deselecting = !all.isEmpty && selected == all.count

        for indexPath in all {
            if deselecting {
                tableView.deselectRow(at: indexPath, animated: false)
            } else {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }

        updateBatchItems()
    }

    @objc private func deleteSelected() {
        let items = (tableView.indexPathsForSelectedRows ?? []).compactMap(item(at:))
        guard !items.isEmpty else { return }

        // 自己起一个而不是借 `hierarchy_showAlert`：那个助手挂在 Hierarchy 的 category 里，
        // 名字与作用域都属于另一个工具。顺便把条数写进文案。
        let alert = UIAlertController(
            title: nil,
            message: "Delete \(items.count) key\(items.count > 1 ? "s" : "")?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // 先退出编辑态再重建：选中的行都没了，留在编辑态只会剩下一地多选高亮
            self?.setEditing(false, animated: true)
            self?.delete(items)
        })
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension UserDefaultsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        // 搜索与编辑态互斥：搜索激活时导航栏会把两边的按钮收起来，
        // 留在编辑态就既看不到「Done」也看不到批量条
        if searchController.isActive, isEditing {
            setEditing(false, animated: false)
        }

        keyword = searchController.searchBar.text ?? ""
        reloadSections()
    }
}

// MARK: - 选中与侧滑

extension UserDefaultsViewController {

    /// 编辑态下的勾选/取消勾选只用来更新批量条的计数。
    /// 非编辑态那条路不在这里：那是 cell 发 trigger、基类路由到行自己的 `onTrigger`。
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        updateBatchItems()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        updateBatchItems()
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let item = item(at: indexPath) else { return nil }

        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.delete([item])
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
