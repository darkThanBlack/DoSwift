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

    /// 路径项能画出来的最小信息：一个展示名。**没有 id** —— 身份由业务自己的 model 承载，
    /// 取内容时框架把同一个值原样回传，业务 `as?` 收窄即可。
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

    /// 列表一行所需的展示信息。框架只读 —— 界面状态（哪层在加载、滚到哪儿）一律不回写 model。
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
