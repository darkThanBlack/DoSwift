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

    // MARK: - 节点

    /// 沙盒文件节点：直接包住一个 `file://` URL。
    ///
    /// 框架的 ``DO.FileNode`` 里**没有 id** —— 「路径栈按什么入栈」是业务自己的账，
    /// 这里取 `standardizedFileURL.path`：同一个文件不管从哪一层被问到，拿到的 id 都一致。
    struct SandboxFileNode: DO.FileNode {

        let url: URL

        let nodeKind: DO.FileNodeKind

        let nodeSize: Int64?

        let nodeIconToken: String?

        /// 定制展示名；nil = 用 `lastPathComponent`
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

        /// 业务侧身份：标准化后的绝对路径
        var nodeID: String { return url.standardizedFileURL.path }

        var nodeName: String? {
            if let displayName = displayName { return displayName }
            let name = url.lastPathComponent
            return name.isEmpty ? url.standardizedFileURL.path : name
        }

        /// 按 URL 探测类型 / 大小，并顺手算出图标 token。
        ///
        /// - Returns: 文件不存在（比如枚举与读取之间被删掉）时返回 nil，调用方直接跳过这一行 ——
        ///   宁可少一行，也不画一个点不开的幽灵节点。
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
                /// 文件夹交给 ``DO.FileBrowserStyle`` 的兜底图标（folder.fill）
                nodeIconToken: isFolder ? nil : DO.FileBrowserStyle.token(forExtension: url.pathExtension)
            )
        }

        /// 排序：文件夹在前，同类按文件名自然序（`文件2` < `文件10`）
        static func isOrderedBefore(_ lhs: DO.SandboxFileNode, _ rhs: DO.SandboxFileNode) -> Bool {
            if lhs.nodeKind != rhs.nodeKind {
                return lhs.nodeKind == .folder
            }
            let l: String = lhs.url.lastPathComponent
            let r: String = rhs.url.lastPathComponent
            return l.localizedStandardCompare(r) == .orderedAscending
        }
    }

    // MARK: - 数据源

    /// 真实沙盒：``DO.FileBrowserNodeDataSource`` 的实现 —— 用 `FileManager` 列目录，**异步 + 带缓存**。
    ///
    /// 路径不归它管（那是页面的路径栈），接口契约与浏览器的内容源完全一致 ——
    /// 换一套实现即换数据源，``DO.FileBrowserView`` 一行都不用改。
    ///
    /// - 第一次要某一层：后台线程列目录（真实 IO），主线程回调，于是能看到 loading 文案；
    /// - 之后要同一层：缓存命中、**同步**回调 —— 点面包屑回退是瞬时的；
    /// - 枚举失败（权限 / 目录被删）：`.failure`，框架直接显示 `localizedDescription`。
    ///
    /// - Important: 过期回调由业务自己丢（框架不认请求序号）—— 这里用 ``currentID`` 认「当前层」，
    ///   快速连点、旧请求晚回来时直接不回调。
    final class SandboxFileProvider: DO.FileBrowserNodeDataSource {

        /// 沙盒根（`NSHomeDirectory()`，与 DoKit 原版一致）
        let rootURL: URL

        /// 业务侧认定的「当前层」：过期回调在这里丢掉
        var currentID: String?

        private var levelCache: [String: [any DO.FileNode]] = [:]

        private let queue = DispatchQueue(label: "do.sandbox.filebrowser", qos: .userInitiated)

        init(rootURL: URL? = nil) {
            self.rootURL = rootURL ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        }

        /// 浏览器入口：根节点
        var root: DO.SandboxFileNode {
            return DO.SandboxFileNode(url: rootURL, nodeKind: .folder, displayName: "沙盒")
        }

        /// 业务侧改了数据后重新要一次（删除文件之后）
        func invalidate() {
            levelCache.removeAll()
        }

        /// 某一层当前的内容：框架只报「第几行」，把行号映射回自己的节点是业务的事
        func level(_ id: String) -> [any DO.FileNode] {
            return levelCache[id] ?? []
        }

        // MARK: - DO.FileBrowserNodeDataSource

        func fileBrowser(
            _ browser: DO.FileBrowserView,
            nodesOf node: any DO.PathNode,
            completion: @escaping (Result<[any DO.FileNode], Error>) -> Void
        ) {
            /// 路径项就是我们自己交出去的那个 model，收窄回来身份就回来了
            guard let node = node as? DO.SandboxFileNode else {
                completion(.success([]))
                return
            }

            let id: String = node.nodeID
            let url: URL = node.url

            /// 缓存命中：直接同步回调（框架照单收下，不会闪 loading）
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
                    /// 迟到的、已经不是当前层的回调：业务自己丢
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
