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

    /// 浏览器向业务问的**路径**：路径多长 / 第 i 层是什么。
    ///
    /// 这是「业务自己的状态」（它那份路径栈），同步且确定为 O(1) 的纯查询 ——
    /// 所以与真正的内容源分开：两者在真实业务里天然就是两个对象。
    ///
    /// - Important: 框架**不持有路径** —— 它每次现问。「同一层被问两次」是正常的
    ///   （路径条问一遍、取内容前再问一遍末端那项），所以这里必须是**纯查询**，
    ///   不要做「第一次来才算」之类的副作用。
    protocol FileBrowserPathDataSource: AnyObject {

        /// 路径深度（含根）；返回 0 = 没有路径，框架直接落到空态文案（不触发取内容）
        func fileBrowserPathNumbers(_ browser: DO.FileBrowserView) -> Int

        /// 第 index 层的路径项（0 = 根）。返回**业务自己的 model** 即可 —— 框架只读它的 `nodeName`。
        func fileBrowser(_ browser: DO.FileBrowserView, pathItemFor index: Int) -> any DO.PathNode
    }

    // MARK: - 内容源（异步）

    /// 浏览器向业务要的**那一屏内容**：一次 ``DO.FileBrowserView/reloadData()`` 对应一问。
    ///
    /// 取内容的时机只有一个：**路径末端那个节点**（首次给路径、点文件夹行、点面包屑回退，都是它）。
    ///
    /// - Important: 框架**不持有内容** —— 取回来只够画这一屏，转手就交给列表，
    ///   所以「上次那层是什么」框架自己是答不上来的（也不需要）。
    protocol FileBrowserNodeDataSource: AnyObject {

        /// 取 `node` 这一层的内容。
        ///
        /// - Parameters:
        ///   - node: 路径末端（= 用户刚点到的那个）节点，就是业务从 `pathItemFor:` 交出去的同一个值；
        ///     用 `as?` 收窄回自己的类型即可拿到 id / url。
        ///   - completion: **必须回主线程**（框架直接更新 UI）。`.success([])` = 这一层确实没有内容
        ///     （显示空态文案）；`.failure` = 显示这个 error 的 `localizedDescription`（文案由业务随 error 给）。
        ///
        /// - Important: **过期回调由业务自己处理** —— 框架不认请求序号，它也判不出来：你的数据源是同步还是异步、
        ///   请求能不能取消、迟到的那个回调还算不算数，只有业务知道。所以「快速连点多个节点、旧请求晚回来」
        ///   这种形态请在业务侧解决（认出不是当前层就别调 completion，或干脆取消请求）；
        ///   缓存命中可以直接**同步**回调，框架不会闪 loading。
        func fileBrowser(
            _ browser: DO.FileBrowserView,
            nodesOf node: any DO.PathNode,
            completion: @escaping (Result<[any DO.FileNode], Error>) -> Void
        )
    }

    // MARK: - 事件

    /// 用户意图的出口：只报「第几项」。
    ///
    /// 框架不持有内容，所以也交不出节点 —— 下标就是它知道的全部。
    /// 浏览器不推栈、不缓存、不知道下一层是哪一层：这些回调就是上层接手的地方
    /// （改自己的路径栈 → 再调一次 ``DO.FileBrowserView/reloadData()``）。
    ///
    /// - Important: 全部回调**同步、主线程**；index 口径与数据源一致（面包屑 0 = 根，列表 0 = 第一行）。
    protocol FileBrowserDelegate: AnyObject {

        /// 面包屑第 index 项被点了，问一句「这次要不要投递」。
        ///
        /// 返回 `false` 则这次点击**整个作废**：框架不上报事件、不改任何东西 —— 提示由业务在这里自己给。
        ///
        /// - Note: 默认实现只放行**祖先层**；当前层（末项）点了不投递 —— 「回到我在的地方」不构成一次切换。
        ///   需要「点当前层做事」（复制路径 / 刷新）的业务覆盖本方法，再在 ``didSelectPathAt`` 里按 `index` 分辨。
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectPathAt index: Int) -> Bool

        /// 面包屑第 index 项被点了（0 = 根），且已通过 ``canSelectPathAt``
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectPathAt index: Int)

        /// 列表第 index 行「将要打开」，问一句允许吗？
        ///
        /// **每行都问**，框架不替你区分文件夹行 / 文件行 —— 它只有行号，「哪一行进不去」是业务规则。
        func fileBrowser(_ browser: DO.FileBrowserView, canSelectNodeAt index: Int) -> Bool

        /// 列表第 index 行被点了，且已通过 ``canSelectNodeAt``
        func fileBrowser(_ browser: DO.FileBrowserView, didSelectNodeAt index: Int)

        /// 列表第 index 行「能不能划出删除」；默认 `false`（只读浏览）
        func fileBrowser(_ browser: DO.FileBrowserView, canDeleteNodeAt index: Int) -> Bool

        /// 列表第 index 行的删除被确认了（业务在这一步真正删数据，然后自己重画）
        func fileBrowser(_ browser: DO.FileBrowserView, didDeleteNodeAt index: Int)
    }
}

// MARK: - 默认实现
//
// - Note: 协议扩展只能写在文件作用域（不能嵌在 `extension DO { }` 里）。
//   `didSelectNodeAt` 刻意不给默认实现 —— 它是列表唯一的出口，漏写等于列表点不动。

extension DO.FileBrowserDelegate {

    /// 默认放行祖先层；当前层（末项）不投递
    ///
    /// - Note: 「末项是惰性的」是浏览器层的策略，路径条自己不知道。要看深度只能问浏览器 ——
    ///   ``DO.FileBrowserPathDataSource/fileBrowserPathNumbers(_:)`` 契约上是纯 O(1) 查询，重复问没有副作用。
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
