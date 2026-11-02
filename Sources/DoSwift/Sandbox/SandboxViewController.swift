//
//  SandboxViewController.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import QuickLook
import UIKit

extension DO {

    /// 沙盒文件浏览器。
    ///
    /// 界面全部由 ``DO.FileBrowserView`` 提供：路径条 + 列表 + 状态文案；
    /// 本页只做业务那一半 —— 自己的路径栈、内容源、以及「点文件 / 点面包屑」之后做什么。
    ///
    /// 交互（与 DoKit 原版一致，导航方式换成面包屑）：
    /// - 点文件夹：路径栈压一层，重新取内容；
    /// - 点面包屑：回退到该层（缓存命中 → 同步回调，不闪 loading）；点当前层（末端）复制当前完整路径；
    /// - 点文件：弹「本地预览 / 分享 / 复制路径」；
    /// - 左划一行：删除（原版即如此，没有二次确认）。
    @objc(DOSandboxViewController)
    final class SandboxViewController: UIViewController, DO.FileBrowserPathDataSource, DO.FileBrowserDelegate {

        /// 内容源：真实 FileManager（换一套实现即换数据源，本页其余代码不动）
        private let provider = DO.SandboxFileProvider()

        /// 路径栈：现在在哪一层（框架不持有 paths，所以这就是唯一那份账）
        private lazy var stack = DO.FilePathStack(rootID: provider.root.nodeID)

        /// id → 节点：路径条问「第 i 项是什么」时得拿得出来
        private var nodeCache: [String: DO.SandboxFileNode] = [:]

        /// 当前要预览的文件（`QLPreviewControllerDataSource` 只认它）
        private var previewURL: URL?

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .systemBackground
            view.addSubview(browser)

            browser.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                browser.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                browser.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                browser.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                browser.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])

            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(close)
            )

            browser.pathDataSource = self
            browser.nodeDataSource = provider
            browser.delegate = self

            reset()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            /// 文件可能被外部改过（预览 / 分享回来也算）：保留当前层，但内容重取
            provider.invalidate()
            reload()
        }

        @objc func close() {
            DO.SandboxPlugin.shared.hide()
        }

        // MARK: - Interface

        /// 回到沙盒根。插件每次打开都从根开始（与其它工具「重开即刷新」一致）。
        func reset() {
            stack = DO.FilePathStack(rootID: provider.root.nodeID)
            nodeCache[provider.root.nodeID] = provider.root
            provider.invalidate()
            reload()
        }

        // MARK: - DO.FileBrowserPathDataSource

        func fileBrowserPathNumbers(_ browser: DO.FileBrowserView) -> Int {
            return stack.ids.count
        }

        /// 路径项就是我们自己的 model —— 框架只读 `nodeName`；身份在后面 `nodesOf` 里靠 `as?` 收窄拿回来
        func fileBrowser(_ browser: DO.FileBrowserView, pathItemFor index: Int) -> any DO.PathNode {
            return nodeCache[stack.ids[index]] ?? provider.root
        }

        // MARK: - DO.FileBrowserDelegate

        /// 当前层也要能点（点了复制路径），所以这里全部放行；
        /// 「点了之后做什么」在 ``didSelectPathAt`` 里按是否为末项区分。
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool {
            return true
        }

        /// 面包屑：祖先层 = 回退到该层重画；当前层 = 复制「我在哪」的完整路径
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int) {
            guard index < stack.depth - 1 else {
                copyPath(stack.topID)
                return
            }

            stack.trim(toDepth: index + 1)
            reload()
        }

        /// 点了一行：文件夹往下走一层，文件交给「预览 / 分享」
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectNodeAt index: Int) {
            guard let node = node(at: index) else { return }

            switch node.nodeKind {
            case .folder:
                nodeCache[node.nodeID] = node
                stack.push(node.nodeID)
                reload()

            case .file:
                showActions(for: node.url)
            }
        }

        /// 沙盒浏览器要能删文件（原版行为：划出「删除」即删）
        func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool {
            return true
        }

        func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int) {
            guard let node = node(at: index) else { return }

            do {
                try FileManager.default.removeItem(at: node.url)
            } catch {
                presentError(error)
            }

            provider.invalidate()
            reload()
        }

        // MARK: - Actions

        private func showActions(for url: URL) {
            let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            let alert = UIAlertController(title: url.lastPathComponent, message: nil, preferredStyle: style)

            alert.addAction(UIAlertAction(title: "本地预览", style: .default) { [weak self] _ in
                self?.preview(url)
            })
            alert.addAction(UIAlertAction(title: "分享", style: .default) { [weak self] _ in
                self?.share(url)
            })
            alert.addAction(UIAlertAction(title: "复制路径", style: .default) { [weak self] _ in
                self?.copyPath(url.path)
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))

            if let popover = alert.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0.0, height: 0.0)
            }
            present(alert, animated: true)
        }

        /// 预览分三条路：结构化文本就地解析、SQLite 进表浏览、其余交给系统 QuickLook
        private func preview(_ url: URL) {
            if let text = DO.SandboxFilePreview.text(for: url) {
                let detail = DO.PlainTextViewController(title: url.lastPathComponent, text: text)
                navigationController?.pushViewController(detail, animated: true)
                return
            }

            if DO.SandboxDatabase.isSQLiteFile(url) {
                let detail = DO.SandboxDatabaseViewController(url: url)
                navigationController?.pushViewController(detail, animated: true)
                return
            }

            previewURL = url

            let controller = QLPreviewController()
            controller.dataSource = self
            present(controller, animated: true)
        }

        private func share(_ url: URL) {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)

            if let popover = controller.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0.0, height: 0.0)
            }
            present(controller, animated: true)
        }

        /// 复制到剪贴板；与应用内其它「复制」一致，给一次轻反馈
        private func copyPath(_ path: String) {
            UIPasteboard.general.string = path
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        private func presentError(_ error: Error) {
            let alert = UIAlertController(title: "操作失败", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default))
            present(alert, animated: true)
        }

        // MARK: - Data

        /// **业务唯一的写入口**：改自己的路径栈，然后让浏览器重画 + 重取内容
        private func reload() {
            /// 过期保护是业务的事（框架不认请求序号）：先认下「当前层」，迟到的回调由数据源自己丢
            provider.currentID = stack.topID

            updateTitle()
            browser.reloadData()
        }

        /// 标题跟着当前层走（根 = 「沙盒」，与原版把目录名放导航栏一致）
        private func updateTitle() {
            if stack.topID == provider.root.nodeID {
                title = "沙盒"
            } else {
                title = nodeCache[stack.topID]?.nodeName ?? URL(fileURLWithPath: stack.topID).lastPathComponent
            }
        }

        /// 「第几行」→ 自己的节点：框架只报下标，这份映射是业务的事
        private func node(at index: Int) -> DO.SandboxFileNode? {
            let level = provider.level(stack.topID)
            guard level.indices.contains(index) else { return nil }
            return level[index] as? DO.SandboxFileNode
        }

        // MARK: - Subviews

        private lazy var browser = DO.FileBrowserView()
    }
}

// MARK: - QuickLook

extension DO.SandboxViewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return previewURL == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        /// `NSURL` 自带 `QLPreviewItem` 实现，直接交给系统
        return (previewURL ?? provider.rootURL) as NSURL
    }
}
