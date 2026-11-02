//
//  FileBrowserView.swift
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

    /// 文件浏览器 = 路径条 + 列表 + 状态文案，自己不持有任何数据。
    ///
    /// `reloadData()` 里现问路径与末端节点那一屏内容；出口只报「第几项」，换不换路径由业务决定。
    /// 于是「现在在哪层 / 这层有什么」始终只有业务那一份账，没有第二份副本可以变味。
    ///
    /// loading / empty / 失败是本类的内部 UI 属性，不对外暴露 —— 只有它知道是「还没取回来」还是
    /// 「真的是空」。
    @objc(DOFileBrowserView)
    final class FileBrowserView: UIView {

        /// 路径源（同步、确定）：现在在哪几层、每层叫什么
        weak var pathDataSource: (any DO.FileBrowserPathDataSource)?

        /// 内容源（异步）：某个节点里有什么
        weak var nodeDataSource: (any DO.FileBrowserNodeDataSource)?

        weak var delegate: (any DO.FileBrowserDelegate)?

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Interface

        /// 重画这一屏：现问路径 + 现取末端节点的内容。业务改完自己的路径栈后调它（重试同理）。
        func reloadData() {
            pathBar.reloadData()

            requestNodes()
        }

        // MARK: - Data

        private func requestNodes() {
            guard let node = currentPathItem(), let nodeDataSource = nodeDataSource else {
                /// 没有路径 / 没挂内容源时没有「正在加载」可言，直接落到空
                show(stateText: DO.FileBrowserStyle.emptyText)
                return
            }

            show(stateText: DO.FileBrowserStyle.loadingText)

            nodeDataSource.fileBrowser(self, nodesOf: node) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let nodes):
                    self.listView.update(nodes)
                    self.show(stateText: nodes.isEmpty ? DO.FileBrowserStyle.emptyText : nil)

                case .failure(let error):
                    /// 清掉上一个节点的残留，只留这一句文案
                    self.listView.update([])
                    self.show(stateText: error.localizedDescription)
                }
            }
        }

        /// 路径末端那一项 = 取内容的触发点（末端就是用户刚点到的那个节点）
        private func currentPathItem() -> (any DO.PathNode)? {
            guard let pathDataSource = pathDataSource else { return nil }

            let numbers: Int = pathDataSource.fileBrowserPathNumbers(self)
            guard numbers > 0 else { return nil }

            return pathDataSource.fileBrowser(self, pathItemFor: numbers - 1)
        }

        /// 四种状态共用一句文案：`nil` = 有内容（显示列表），否则列表藏起来、居中显示这句话
        private func show(stateText: String?) {
            stateLabel.text = stateText
            stateLabel.isHidden = (stateText == nil)
            listView.isHidden = (stateText != nil)
        }

        // MARK: - View

        private func loadViews(in box: UIView) {
            box.addSubview(pathBar)
            box.addSubview(contentStack)

            pathBar.translatesAutoresizingMaskIntoConstraints = false
            contentStack.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                pathBar.topAnchor.constraint(equalTo: box.topAnchor),
                pathBar.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                pathBar.trailingAnchor.constraint(equalTo: box.trailingAnchor),

                contentStack.topAnchor.constraint(equalTo: pathBar.bottomAnchor),
                contentStack.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                contentStack.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            ])

            pathBar.dataSource = self
            pathBar.delegate = self
            listView.delegate = self

            show(stateText: nil)
        }

        private lazy var pathBar = DO.PathBarView()

        private lazy var listView = DO.FileListView()

        /// 状态文案（加载中 / 暂无内容 / 失败）：铺满内容区，文字自然居中对齐
        private lazy var stateLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 0
            view.textAlignment = .center
            view.font = DO.FileBrowserStyle.stateFont
            view.textColor = DO.FileBrowserStyle.lightTextColor
            return view
        }()

        /// 列表与状态文案互斥：`.fill` 的 stack 里藏掉一个，剩下的自然占满
        private lazy var contentStack: UIStackView = {
            let view = UIStackView(arrangedSubviews: [listView, stateLabel])
            view.axis = .vertical
            view.alignment = .fill
            view.distribution = .fill
            view.spacing = 0.0
            return view
        }()
    }
}

// MARK: - 子组件 ←→ 业务（容器自己就是路径条的 dataSource / delegate，业务只实现容器这一层）

extension DO.FileBrowserView: DO.PathBarViewDataSource {

    func pathBarItemNumbers(_ bar: DO.PathBarView) -> Int {
        return pathDataSource?.fileBrowserPathNumbers(self) ?? 0
    }

    func pathBar(_ bar: DO.PathBarView, itemFor index: Int) -> any DO.PathNode {
        return pathDataSource!.fileBrowser(self, pathItemFor: index)
    }
}

extension DO.FileBrowserView: DO.PathBarViewDelegate {

    func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool {
        return delegate?.fileBrowser(self, canSelectPathAt: index) ?? true
    }

    func pathBar(_ bar: DO.PathBarView, didSelectAt index: Int) {
        delegate?.fileBrowser(self, didSelectPathAt: index)
    }
}

extension DO.FileBrowserView: DO.FileListViewDelegate {

    func fileListView(_ list: DO.FileListView, didSelectAt index: Int) {
        /// 每一行都过闸（框架只有行号，不替业务区分文件夹 / 文件行）
        guard (delegate?.fileBrowser(self, canSelectNodeAt: index) ?? true) else { return }

        delegate?.fileBrowser(self, didSelectNodeAt: index)
    }

    func fileListView(_ list: DO.FileListView, canDeleteAt index: Int) -> Bool {
        return delegate?.fileBrowser(self, canDeleteNodeAt: index) ?? false
    }

    func fileListView(_ list: DO.FileListView, didDeleteAt index: Int) {
        delegate?.fileBrowser(self, didDeleteNodeAt: index)
    }
}
