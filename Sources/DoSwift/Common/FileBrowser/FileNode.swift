//
//  FileNode.swift
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

    // MARK: - 节点契约

    /// 路径条（面包屑）能画出来的最小信息：一个展示名。
    ///
    /// 框架**只读 `nodeName`** —— 它是纯 UI，不做身份识别，所以这里**没有 id**：
    /// 「路径项是什么」由业务自己定（业务拿自己的 model 实现本协议，自带 id / url 等字段），
    /// 框架只取 `nodeName` 去画；要拿回身份也不用框架给，取内容时框架会把**同一个值**
    /// 原样回传（见 ``DO.FileBrowserNodeDataSource/fileBrowser(_:nodesOf:completion:)``），
    /// 业务 `as?` 收窄回自己的类型即可。
    protocol PathNode {

        /// 展示名；nil 或空串 = 不展示（路径条会给一个占位符，列表行则整块隐藏）
        var nodeName: String? { get }
    }

    /// 节点类型
    enum FileNodeKind: Equatable {

        /// 文件夹：可进入
        case folder

        /// 文件：可打开（预览 / 分享由业务决定）
        case file
    }

    /// 文件 / 文件夹节点：列表一行所需的**展示信息**。
    ///
    /// 框架**只读**它 —— 界面状态（哪层在加载、滚到哪儿）一律不回写 model。
    protocol FileNode: DO.PathNode {

        var nodeKind: DO.FileNodeKind { get }

        /// 文件大小（字节）；文件夹通常不给
        var nodeSize: Int64? { get }

        /// 图标 token；默认实现把它当 SF Symbol 名（见 ``DO.FileBrowserStyle/nodeImage(_:)``）
        var nodeIconToken: String? { get }
    }
}

extension DO.FileNode {

    var nodeSize: Int64? { return nil }

    var nodeIconToken: String? { return nil }
}
