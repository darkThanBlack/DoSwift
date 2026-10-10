//
//  HierarchyDetailViewController.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyDetailViewController.m / .h
//

import UIKit

let HierarchyChangeNotificationName = Notification.Name("DoraemonHierarchyChangeNotification")

class HierarchyDetailViewController: HierarchyTableViewController {

    var selectView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UI Structure"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissDetail)
        )

        loadData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveChangeNotification(_:)),
            name: HierarchyChangeNotificationName,
            object: nil
        )
    }

    // MARK: - Data

    // Property lists come from HierarchyPropertyEngine (JSON-driven).
    private func loadData() {
        guard let view = selectView else { return }

        // 尺寸组在前、属性组在后，**不再分页**：读一个 view 的顺序本来就是
        // 「多大、在哪」→「是什么」，切成两页只会让人来回切。
        // 组标题由 JSON 里的分组名给出，两段天然分得清。
        dataArray = HierarchyPropertyEngine.shared.sizeCategoryModels(for: view)
            + HierarchyPropertyEngine.shared.categoryModels(for: view)

        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func didReceiveChangeNotification(_ notification: Notification) {
        loadData()
    }

    // MARK: - TableView Override

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataArray[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.cellClass, for: indexPath)
        if let detailCell = cell as? HierarchyDetailTitleCell {
            detailCell.model = model
            detailCell.detailLabel.textAlignment = .left
        }
        cell.separatorInset = model.separatorInsets
        return cell
    }

    @objc func dismissDetail() {
        dismiss(animated: true)
    }
}
