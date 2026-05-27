//
//  HierarchyTableViewController.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyTableViewController.m / .h
//
//  Note: ObjC extends DoraemonBaseViewController with bigTitleView.
//  Swift version uses plain UIViewController.
//

import UIKit

class HierarchyTableViewController: UIViewController {

    private(set) lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.delegate = self
        tv.dataSource = self
        tv.bounces = false
        tv.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        tv.estimatedRowHeight = UITableView.automaticDimension
        tv.estimatedSectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.register(HierarchySwitchCell.self, forCellReuseIdentifier: "HierarchySwitchCell")
        tv.register(HierarchyDetailTitleCell.self, forCellReuseIdentifier: "HierarchyDetailTitleCell")
        tv.register(HierarchySelectorCell.self, forCellReuseIdentifier: "HierarchySelectorCell")
        if #available(iOS 11.0, *) {
            tv.contentInsetAdjustmentBehavior = .automatic
        }
        return tv
    }()

    var dataArray: [HierarchyCategoryModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}

extension HierarchyTableViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        dataArray.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataArray[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataArray[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.cellClass, for: indexPath)
        // Use KVC to set model since Swift cell hierarchy differs from ObjC
        cell.setValue(model, forKey: "model")
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let model = dataArray[section]
        guard let title = model.title else { return nil }
        let header = HierarchyHeaderView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        header.titleLabel.text = title
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        dataArray[section].title != nil ? 40 : CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataArray[indexPath.section].items[indexPath.row].block?()
    }
}
