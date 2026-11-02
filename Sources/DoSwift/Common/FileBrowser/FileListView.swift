//
//  FileListView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// ``DO.FileListView`` 的事件出口
    protocol FileListViewDelegate: AnyObject {

        /// 第 index 行被点了（哑组件只认下标，不认业务模型）
        func fileListView(_ list: DO.FileListView, didSelectAt index: Int)

        /// 第 index 行能不能划出「删除」；默认不提供（只读浏览）
        func fileListView(_ list: DO.FileListView, canDeleteAt index: Int) -> Bool

        /// 第 index 行的删除被点确认了（业务删完数据后自己重画）
        func fileListView(_ list: DO.FileListView, didDeleteAt index: Int)
    }

    /// 文件列表的**哑组件**：给什么画什么，只回报「第几行被点了」。
    ///
    /// 不认识路径栈、不认识业务模型、不判断「在加载还是真的空」—— 内容由上层组织好后 ``update(_:)`` 一把传入。
    /// 行高自适应，故行视图只要把内容撑起来即可。
    ///
    /// - Note: 表格只是承载。对外契约只有 node（`[any DO.FileNode]`），`IndexPath` / cell 一概不外露；
    ///   换承载只需重写这一个文件。
    @objc(DOFileListView)
    final class FileListView: UIView {

        weak var delegate: (any DO.FileListViewDelegate)?

        /// 当前展示的内容（顺序即展示顺序）
        private(set) var nodes: [any DO.FileNode] = []

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Interface

        func update(_ nodes: [any DO.FileNode]) {
            self.nodes = nodes

            tableView.reloadData()
        }

        // MARK: - View

        private func loadViews(in box: UIView) {
            backgroundColor = DO.FileBrowserStyle.backgroundColor

            box.addSubview(tableView)
            tableView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: box.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            ])

            /// 干掉末行分隔线（省掉「是不是最后一行」在全链路上传参）
            tableView.tableFooterView = UIView()
        }

        // MARK: - Subviews

        private lazy var tableView: UITableView = {
            let view = UITableView(frame: .zero, style: .plain)
            view.dataSource = self
            view.delegate = self
            view.register(DO.FileBrowserNodeCell.self, forCellReuseIdentifier: Self.cellIdentifier)
            view.backgroundColor = .clear
            /// 行高交给行视图自己撑
            view.rowHeight = UITableView.automaticDimension
            view.estimatedRowHeight = 64.0
            view.separatorInset = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0)
            return view
        }()

        private static let cellIdentifier = String(describing: DO.FileBrowserNodeCell.self)
    }
}

extension DO.FileListViewDelegate {

    /// 默认只读
    func fileListView(_ list: DO.FileListView, canDeleteAt index: Int) -> Bool {
        return false
    }

    /// 默认不关心
    func fileListView(_ list: DO.FileListView, didDeleteAt index: Int) {}
}

extension DO.FileListView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellIdentifier,
            for: indexPath
        ) as? DO.FileBrowserNodeCell
        if let cell = cell, nodes.indices.contains(indexPath.row) {
            cell.config(node: nodes[indexPath.row])
        }
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard nodes.indices.contains(indexPath.row) else { return }
        delegate?.fileListView(self, didSelectAt: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard nodes.indices.contains(indexPath.row),
              (delegate?.fileListView(self, canDeleteAt: indexPath.row) ?? false) else {
            return nil
        }

        let action = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            completion(true)
            self.delegate?.fileListView(self, didDeleteAt: indexPath.row)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
