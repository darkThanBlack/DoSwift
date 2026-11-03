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

    /// Path bar + list + state text, holding no data of its own.
    ///
    /// `reloadData()` asks for the path and the children of its last node. Every output is an
    /// index, so switching path stays a business decision and there is one source of truth.
    ///
    /// Loading / empty / failure are private UI state: only this class can tell "not yet"
    /// from "truly empty".
    @objc(DOFileBrowserView)
    final class FileBrowserView: UIView {

        /// Path source (sync): depth and names.
        weak var pathDataSource: (any DO.FileBrowserPathDataSource)?

        /// Node source (async): children of one node.
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

        /// Redraw: re-ask the path, refetch the last node. Call it after mutating your stack.
        func reloadData() {
            pathBar.reloadData()

            requestNodes()
        }

        // MARK: - Data

        private func requestNodes() {
            guard let node = currentPathItem(), let nodeDataSource = nodeDataSource else {
                /// No path or no node source: skip loading, go straight to empty.
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
                    /// Drop the previous level's rows, keep only the message.
                    self.listView.update([])
                    self.show(stateText: error.localizedDescription)
                }
            }
        }

        /// The last path item is the node whose children we fetch.
        private func currentPathItem() -> (any DO.PathNode)? {
            guard let pathDataSource = pathDataSource else { return nil }

            let numbers: Int = pathDataSource.fileBrowserPathNumbers(self)
            guard numbers > 0 else { return nil }

            return pathDataSource.fileBrowser(self, pathItemFor: numbers - 1)
        }

        /// `nil` = show the list; otherwise hide it and center this message.
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

        /// State text fills the content area.
        private lazy var stateLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 0
            view.textAlignment = .center
            view.font = DO.FileBrowserStyle.stateFont
            view.textColor = DO.FileBrowserStyle.lightTextColor
            return view
        }()

        /// List and state text are mutually exclusive; hiding one lets the other fill.
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

// MARK: - Wiring (this container is the path bar's data source / delegate)

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
        /// Every row goes through the gate; the framework knows indices, not kinds.
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
