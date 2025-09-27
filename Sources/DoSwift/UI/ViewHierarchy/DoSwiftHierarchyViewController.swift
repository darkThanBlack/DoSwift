//
//  DoSwiftHierarchyViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/27.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构查看器主控制器
public class DoSwiftHierarchyViewController: UIViewController {

    // MARK: - Properties

    private var hierarchyNodes: [DoSwiftViewNode] = []
    private var flattenedNodes: [DoSwiftViewNode] = []
    private var selectedNode: DoSwiftViewNode?

    // MARK: - UI Elements

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["层级结构", "属性详情"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()

    private lazy var hierarchyTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DoSwiftHierarchyCell.self, forCellReuseIdentifier: DoSwiftHierarchyCell.identifier)
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        return tableView
    }()

    private lazy var propertyTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DoSwiftPropertyCell.self, forCellReuseIdentifier: DoSwiftPropertyCell.identifier)
        tableView.isHidden = true
        return tableView
    }()

    private lazy var refreshButton: UIBarButtonItem = {
        UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshHierarchy)
        )
    }()

    private var propertyCategories: [DoSwiftPropertyCategory] = []

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadViews(in: view)
        loadHierarchy()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DoSwiftHierarchyHelper.shared.removeAllHighlights()
    }

    // MARK: - Setup

    private func loadViews(in box: UIView) {
        title = "UI 结构查看器"
        box.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = refreshButton

        [segmentedControl, hierarchyTableView, propertyTableView].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        // Segmented Control
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: box.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Hierarchy Table View
        NSLayoutConstraint.activate([
            hierarchyTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            hierarchyTableView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            hierarchyTableView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            hierarchyTableView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        ])

        // Property Table View
        NSLayoutConstraint.activate([
            propertyTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            propertyTableView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            propertyTableView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            propertyTableView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        ])
    }

    // MARK: - Data Loading

    private func loadHierarchy() {
        hierarchyNodes = DoSwiftHierarchyHelper.shared.buildHierarchyTree()
        flattenedNodes = flattenHierarchy(nodes: hierarchyNodes)
        hierarchyTableView.reloadData()
    }

    private func flattenHierarchy(nodes: [DoSwiftViewNode]) -> [DoSwiftViewNode] {
        var result: [DoSwiftViewNode] = []

        for node in nodes {
            result.append(node)
            if node.isExpanded {
                result.append(contentsOf: flattenHierarchy(nodes: node.children))
            }
        }

        return result
    }

    private func loadPropertiesForSelectedNode() {
        guard let selectedNode = selectedNode,
              let view = selectedNode.view else {
            propertyCategories = []
            propertyTableView.reloadData()
            return
        }

        propertyCategories = DoSwiftPropertyInspector.shared.getPropertyCategories(for: view)
        propertyTableView.reloadData()
    }

    // MARK: - Actions

    @objc private func refreshHierarchy() {
        DoSwiftHierarchyHelper.shared.removeAllHighlights()
        loadHierarchy()

        let alert = UIAlertController(title: "刷新完成", message: "UI 结构已更新", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    @objc private func segmentChanged() {
        let isHierarchyMode = segmentedControl.selectedSegmentIndex == 0

        hierarchyTableView.isHidden = !isHierarchyMode
        propertyTableView.isHidden = isHierarchyMode

        if !isHierarchyMode {
            loadPropertiesForSelectedNode()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension DoSwiftHierarchyViewController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView === hierarchyTableView {
            return 1
        } else {
            return propertyCategories.count
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === hierarchyTableView {
            return flattenedNodes.count
        } else {
            let category = propertyCategories[section]
            return category.isExpanded ? category.properties.count : 0
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView === hierarchyTableView {
            return "视图层级 (\(hierarchyNodes.count) 个窗口)"
        } else {
            return propertyCategories[section].name
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === hierarchyTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: DoSwiftHierarchyCell.identifier, for: indexPath) as! DoSwiftHierarchyCell
            let node = flattenedNodes[indexPath.row]
            cell.configure(with: node)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: DoSwiftPropertyCell.identifier, for: indexPath) as! DoSwiftPropertyCell
            let property = propertyCategories[indexPath.section].properties[indexPath.row]
            cell.configure(with: property)
            cell.valueChangeCallback = { [weak self] newValue in
                DoSwiftPropertyInspector.shared.updateProperty(property, newValue: newValue)
                self?.loadPropertiesForSelectedNode() // 刷新属性列表
            }
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if tableView === hierarchyTableView {
            let node = flattenedNodes[indexPath.row]

            if node.children.isEmpty {
                // 叶子节点 - 高亮显示并切换到属性页面
                selectedNode = node
                if let view = node.view {
                    DoSwiftHierarchyHelper.shared.highlightView(view)
                }
                segmentedControl.selectedSegmentIndex = 1
                segmentChanged()
            } else {
                // 非叶子节点 - 展开/收起
                node.isExpanded.toggle()
                flattenedNodes = flattenHierarchy(nodes: hierarchyNodes)
                tableView.reloadData()
            }
        } else {
            // 属性表格 - 展开/收起分类
            let category = propertyCategories[indexPath.section]
            category.isExpanded.toggle()
            propertyTableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView === propertyTableView {
            let headerView = DoSwiftPropertyHeaderView()
            let category = propertyCategories[section]
            headerView.configure(with: category) { [weak self] in
                category.isExpanded.toggle()
                self?.propertyTableView.reloadSections(IndexSet(integer: section), with: .fade)
            }
            return headerView
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView === propertyTableView ? 44 : UITableView.automaticDimension
    }
}