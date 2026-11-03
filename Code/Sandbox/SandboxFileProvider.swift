//
//  SandboxFileProvider.swift
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

    // MARK: - Node

    /// A `file://` URL wrapper. ``DO.FileNode`` carries no id, so identity is our call:
    /// `standardizedFileURL.path` stays the same whichever level asks.
    struct SandboxFileNode: DO.FileNode {

        let url: URL

        let nodeKind: DO.FileNodeKind

        let nodeSize: Int64?

        let nodeIconToken: String?

        /// Overrides the display name; nil = `lastPathComponent`.
        let displayName: String?

        init(
            url: URL,
            nodeKind: DO.FileNodeKind,
            nodeSize: Int64? = nil,
            nodeIconToken: String? = nil,
            displayName: String? = nil
        ) {
            self.url = url
            self.nodeKind = nodeKind
            self.nodeSize = nodeSize
            self.nodeIconToken = nodeIconToken
            self.displayName = displayName
        }

        /// Identity: the standardized absolute path.
        var nodeID: String { return url.standardizedFileURL.path }

        var nodeName: String? {
            if let displayName = displayName { return displayName }
            let name = url.lastPathComponent
            return name.isEmpty ? url.standardizedFileURL.path : name
        }

        /// Probes kind / size and picks the icon. nil when the file is gone (deleted between
        /// listing and reading) — better a missing row than a ghost that cannot open.
        static func make(url: URL) -> DO.SandboxFileNode? {
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]) else {
                return nil
            }

            let isFolder: Bool = values.isDirectory ?? false
            let size: Int64? = isFolder ? nil : values.fileSize.map(Int64.init)

            return DO.SandboxFileNode(
                url: url,
                nodeKind: isFolder ? .folder : .file,
                nodeSize: size,
                /// Folders fall back to ``DO.FileBrowserStyle``'s icon.
                nodeIconToken: isFolder ? nil : DO.FileBrowserStyle.token(forExtension: url.pathExtension)
            )
        }

        /// Folders first, then natural name order (`file2` before `file10`).
        static func isOrderedBefore(_ lhs: DO.SandboxFileNode, _ rhs: DO.SandboxFileNode) -> Bool {
            if lhs.nodeKind != rhs.nodeKind {
                return lhs.nodeKind == .folder
            }
            let l: String = lhs.url.lastPathComponent
            let r: String = rhs.url.lastPathComponent
            return l.localizedStandardCompare(r) == .orderedAscending
        }
    }

    // MARK: - Data source

    /// Real node source over `FileManager`: async on first visit, cached after.
    ///
    /// - Important: no request sequence in the framework — ``currentID`` decides, and a stale
    ///   result is simply dropped.
    final class SandboxFileProvider: DO.FileBrowserNodeDataSource {

        /// Sandbox root: `NSHomeDirectory()`.
        let rootURL: URL

        /// Current level; stale callbacks are dropped here.
        var currentID: String?

        private var levelCache: [String: [any DO.FileNode]] = [:]

        private let queue = DispatchQueue(label: "do.sandbox.filebrowser", qos: .userInitiated)

        init(rootURL: URL? = nil) {
            self.rootURL = rootURL ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        }

        /// Browser entry: the root node.
        var root: DO.SandboxFileNode {
            return DO.SandboxFileNode(url: rootURL, nodeKind: .folder, displayName: DO.Text.Sandbox.rootName)
        }

        /// Refetch after the business changed something (a delete).
        func invalidate() {
            levelCache.removeAll()
        }

        /// Children of one level; mapping row indices back is ours.
        func level(_ id: String) -> [any DO.FileNode] {
            return levelCache[id] ?? []
        }

        // MARK: - DO.FileBrowserNodeDataSource

        func fileBrowser(
            _ browser: DO.FileBrowserView,
            nodesOf node: any DO.PathNode,
            completion: @escaping (Result<[any DO.FileNode], Error>) -> Void
        ) {
            /// The model we handed out, cast back.
            guard let node = node as? DO.SandboxFileNode else {
                completion(.success([]))
                return
            }

            let id: String = node.nodeID
            let url: URL = node.url

            /// Cache hit: call back synchronously, so no loading flash.
            if let cached = levelCache[id] {
                completion(.success(cached))
                return
            }

            queue.async { [weak self] in
                guard let self = self else { return }

                let result: Result<[any DO.FileNode], Error>
                do {
                    let urls: [URL] = try FileManager.default.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                        options: []
                    )
                    let nodes: [any DO.FileNode] = urls
                        .compactMap({ DO.SandboxFileNode.make(url: $0) })
                        .sorted(by: DO.SandboxFileNode.isOrderedBefore)
                        .map({ $0 as any DO.FileNode })
                    result = .success(nodes)
                } catch {
                    result = .failure(error)
                }

                DispatchQueue.main.async {
                    /// Late callback for a level we already left.
                    guard self.currentID == id else { return }

                    if case .success(let nodes) = result {
                        self.levelCache[id] = nodes
                    }

                    completion(result)
                }
            }
        }
    }
}
