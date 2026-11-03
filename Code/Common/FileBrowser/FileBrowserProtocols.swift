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

    // MARK: - 路径源（同步、确定）

    /// 浏览器向业务问的**路径**：多长 / 第 i 层是什么。必须是纯查询 —— 框架不持有路径，每次现问，
    /// 同一层被问两次是正常的（路径条一次、取内容前一次），不许有「第一次来才算」之类的副作用。
    protocol FileBrowserPathDataSource: AnyObject {

        /// 路径深度（含根）；返回 0 = 没有路径，框架直接落到空态文案（不触发取内容）
        func fileBrowserPathNumbers(_ browser: DO.FileBrowserView) -> Int

        /// 第 index 层的路径项（0 = 根）。返回**业务自己的 model** 即可 —— 框架只读它的 `nodeName`。
        func fileBrowser(_ browser: DO.FileBrowserView, pathItemFor index: Int) -> any DO.PathNode
    }

    // MARK: - 内容源（异步）

    /// 浏览器要的**那一屏内容**：一次 ``DO.FileBrowserView/reloadData()`` 一问，只问路径末端那个
    /// 节点。框架不持有内容，所以「上次那层是什么」它答不上来（也不需要）。
    protocol FileBrowserNodeDataSource: AnyObject {

        /// 取 `node` 这一层内容。`completion` **必须回主线程**（框架直接更新 UI），也可以同步回调 ——
        /// 缓存命中就走这条路。`.success([])` = 这一层确实没有内容，`.failure` = 显示 `localizedDescription`。
        ///
        /// - Important: 框架不认请求序号 —— 过期回调由业务自己丢（快速连点、旧请求晚回来这类形态）。
        func fileBrowser(
            _ browser: DO.FileBrowserView,
            nodesOf node: any DO.PathNode,
            completion: @escaping (Result<[any DO.FileNode], Error>) -> Void
        )
    }

    // MARK: - 事件

    /// 用户意图的出口：只报第几项 —— 框架不推栈、不缓存，也交不出节点。
    /// 全部回调同步、主线程；index 口径与数据源一致：面包屑 0 = 根，列表 0 = 第一行。
    protocol FileBrowserDelegate: AnyObject {

        /// 面包屑第 index 项被点了，问一句要不要投递：返回 `false` 则这次点击整个作废，提示业务自己给。
        /// 默认只放行祖先层（「回到我在的地方」不算切换）；要在末项做事就覆盖它，再按 `index` 分辨。
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool

        /// 面包屑第 index 项被点了（0 = 根），且已通过 ``canSelectPathAt``
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int)

        /// 列表第 index 行将要打开，问一句允许吗：每行都问，框架只认行号，「哪一行进不去」是业务规则。
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectNodeAt index: Int) -> Bool

        /// 列表第 index 行被点了，且已通过 ``canSelectNodeAt``
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectNodeAt index: Int)

        /// 列表第 index 行「能不能划出删除」；默认 `false`（只读浏览）
        func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool

        /// 列表第 index 行的删除被确认了（业务在这一步真正删数据，然后自己重画）
        func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int)
    }
}

// MARK: - 默认实现（协议扩展只能写在文件作用域；`didSelectNodeAt` 刻意不给默认实现 —— 漏写等于列表点不动）

extension DO.FileBrowserDelegate {

    /// 默认放行祖先层，当前层（末项）不投递 —— 「末项是惰性的」是浏览器层的策略，路径条自己不知道。
    func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool {
        let numbers: Int = browser.pathDataSource?.fileBrowserPathNumbers(browser) ?? 0
        return index < numbers - 1
    }

    /// 默认不关心
    func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int) {}

    /// 默认放行（「哪些行进不去」由业务在这一个方法里表达）
    func fileBrowser(_ browser: DO.FileBrowserView, canSelectNodeAt index: Int) -> Bool {
        return true
    }

    /// 默认只读：不提供删除
    func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool {
        return false
    }

    /// 默认不关心
    func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int) {}
}
