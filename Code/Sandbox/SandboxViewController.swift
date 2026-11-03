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

    /// Sandbox browser. ``DO.FileBrowserView`` draws everything; this page owns the business
    /// half: the path stack, the node source, and what a tap means.
    ///
    /// Folder pushes a level, crumb pops (the last one copies the full path), file opens
    /// preview / share, swipe deletes without confirmation (as the original did).
    @objc(DOSandboxViewController)
    final class SandboxViewController: UIViewController, DO.FileBrowserPathDataSource, DO.FileBrowserDelegate {

        /// Node source over FileManager; swap it and the rest of the page stays.
        private let provider = DO.SandboxFileProvider()

        /// The only record of where we are — the framework keeps no path.
        private lazy var stack = DO.FilePathStack(rootID: provider.root.nodeID)

        /// id → node, so the path bar can answer "what is item i".
        private var nodeCache: [String: DO.SandboxFileNode] = [:]

        /// File being previewed; `QLPreviewControllerDataSource` only sees this.
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

            /// Files may have changed elsewhere: keep the level, refetch its children.
            provider.invalidate()
            reload()
        }

        @objc func close() {
            DO.SandboxPlugin.shared.hide()
        }

        // MARK: - Interface

        /// Back to the root, like every other tool that refreshes on open.
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

        /// Our own model; the bar reads `nodeName` and `nodesOf` casts it back.
        func fileBrowser(_ browser: DO.FileBrowserView, pathItemFor index: Int) -> any DO.PathNode {
            return nodeCache[stack.ids[index]] ?? provider.root
        }

        // MARK: - DO.FileBrowserDelegate

        /// Allow every crumb, the current one included; ``didSelectPathAt`` branches on it.
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool {
            return true
        }

        /// Ancestor = pop and redraw; current = copy the full path.
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int) {
            guard index < stack.depth - 1 else {
                copyPath(stack.topID)
                return
            }

            stack.trim(toDepth: index + 1)
            reload()
        }

        /// Folder descends, file opens preview / share.
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

        /// Swiping to delete removes the file outright, as the original did.
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

            alert.addAction(UIAlertAction(title: DO.Text.Sandbox.preview, style: .default) { [weak self] _ in
                self?.preview(url)
            })
            alert.addAction(UIAlertAction(title: DO.Text.Sandbox.share, style: .default) { [weak self] _ in
                self?.share(url)
            })
            alert.addAction(UIAlertAction(title: DO.Text.Sandbox.copyPath, style: .default) { [weak self] _ in
                self?.copyPath(url.path)
            })
            alert.addAction(UIAlertAction(title: DO.Text.Common.cancel, style: .cancel))

            if let popover = alert.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0.0, height: 0.0)
            }
            present(alert, animated: true)
        }

        /// Three paths: structured text inline, SQLite in a table browser, rest to QuickLook.
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

        /// Copy to the pasteboard with the same light haptic as the other copy actions.
        private func copyPath(_ path: String) {
            UIPasteboard.general.string = path
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        private func presentError(_ error: Error) {
            let alert = UIAlertController(title: DO.Text.Sandbox.actionFailed, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: DO.Text.Common.ok, style: .default))
            present(alert, animated: true)
        }

        // MARK: - Data

        /// The only write path: mutate the stack, then redraw.
        private func reload() {
            /// Stale-guard is ours: mark the current level first, the source drops late replies.
            provider.currentID = stack.topID

            updateTitle()
            browser.reloadData()
        }

        /// Title follows the level; the root shows the sandbox name.
        private func updateTitle() {
            if stack.topID == provider.root.nodeID {
                title = DO.Text.Sandbox.title
            } else {
                title = nodeCache[stack.topID]?.nodeName ?? URL(fileURLWithPath: stack.topID).lastPathComponent
            }
        }

        /// Row index → node; mapping indices back is ours.
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
        /// `NSURL` already conforms to `QLPreviewItem`.
        return (previewURL ?? provider.rootURL) as NSURL
    }
}
