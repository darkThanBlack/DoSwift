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

    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Object", "Size"])
        sc.frame = CGRect(x: 10, y: 10, width: view.bounds.width - 20, height: 30)
        sc.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private var objectDatas: [HierarchyCategoryModel] = []
    private var sizeDatas: [HierarchyCategoryModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "UI Structure"

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        headerView.addSubview(segmentedControl)
        tableView.tableHeaderView = headerView

        loadData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveChangeNotification(_:)),
            name: HierarchyChangeNotificationName,
            object: nil
        )
    }

    // MARK: - Data

    private func loadData() {
        guard let view = selectView else { return }

        objectDatas = view.hierarchy_categoryModels
        sizeDatas = view.hierarchy_sizeCategoryModels

        reloadTableView()
    }

    private func reloadTableView() {
        dataArray.removeAll()
        if segmentedControl.selectedSegmentIndex == 0 {
            dataArray.append(contentsOf: objectDatas)
        } else {
            dataArray.append(contentsOf: sizeDatas)
        }
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        reloadTableView()
    }

    @objc private func didReceiveChangeNotification(_ notification: Notification) {
        loadData()
    }

    // MARK: - TableView Override

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataArray[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.cellClass, for: indexPath)
        cell.setValue(model, forKey: "model")
        if let detailCell = cell as? HierarchyDetailTitleCell {
            detailCell.detailLabel.textAlignment = .left
        }
        cell.separatorInset = model.separatorInsets
        return cell
    }

    func dismissDetail() {
        dismiss(animated: true)
    }
}
