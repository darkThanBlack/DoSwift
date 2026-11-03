//
//  FileBrowserProtocols.swift
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

    // MARK: - Path source (sync)

    /// The path, asked on every reload: how deep, and what sits at layer i.
    /// Pure query only — the browser holds no path, and being asked twice is normal.
    protocol FileBrowserPathDataSource: AnyObject {

        /// Depth including the root. `0` = no path; the browser shows its empty state.
        func fileBrowserPathNumbers(_ browser: DO.FileBrowserView) -> Int

        /// Item at `index` (0 = root). Any business model works; only `nodeName` is read.
        func fileBrowser(_ browser: DO.FileBrowserView, pathItemFor index: Int) -> any DO.PathNode
    }

    // MARK: - Node source (async)

    /// One screen of children, fetched per `reloadData()` for the last path node only.
    /// The browser keeps no cache.
    protocol FileBrowserNodeDataSource: AnyObject {

        /// Children of `node`. `completion` must land on the main thread; sync is fine.
        /// `.success([])` = empty, `.failure` = show `localizedDescription`.
        ///
        /// - Important: no request sequence here — drop stale callbacks yourself.
        func fileBrowser(
            _ browser: DO.FileBrowserView,
            nodesOf node: any DO.PathNode,
            completion: @escaping (Result<[any DO.FileNode], Error>) -> Void
        )
    }

    // MARK: - Events

    /// Reports an index only — the browser never pushes or caches, and hands back no node.
    /// Sync on the main thread; 0 = root (path bar) or first row (list).
    protocol FileBrowserDelegate: AnyObject {

        /// Tap on path item `index`; `false` drops the whole tap.
        /// Default lets ancestors through and keeps the current item inert.
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool

        /// Path item `index` (0 = root) was tapped and passed `canSelectPathAt`.
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int)

        /// Row `index` is about to open; asked per row. Which rows are blocked is a business rule.
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectNodeAt index: Int) -> Bool

        /// Row `index` was tapped and passed `canSelectNodeAt`.
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectNodeAt index: Int)

        /// Whether row `index` can be swiped to delete; `false` by default (read-only).
        func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool

        /// Delete confirmed for row `index` — delete for real here, then reload yourself.
        func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int)
    }
}

// MARK: - Defaults

extension DO.FileBrowserDelegate {

    /// Ancestors only: the current item stays inert, which the path bar knows nothing about.
    func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool {
        let numbers: Int = browser.pathDataSource?.fileBrowserPathNumbers(browser) ?? 0
        return index < numbers - 1
    }

    /// Always allowed by default.
    func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int) {}

    /// Always allowed by default.
    func fileBrowser(_ browser: DO.FileBrowserView, canSelectNodeAt index: Int) -> Bool {
        return true
    }

    /// Read-only by default.
    func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool {
        return false
    }

    /// Nothing to do by default.
    func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int) {}
}
