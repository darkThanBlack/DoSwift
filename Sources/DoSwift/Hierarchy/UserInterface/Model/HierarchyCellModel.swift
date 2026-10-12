//
//  HierarchyCellModel.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyCellModel.m / .h
//
//  Note: 原版还有 switch / selector / stepper 三种分支，服务于「实时修改属性」。
//  该功能尚未实现，所以这里只留只读渲染真正需要的字段——留着 `flag` / `block` /
//  `cellClass` 那几个只会让「它还有人用吗」变成每次读代码都要查一遍的问题。
//

import UIKit

/// 属性面板一行：主标题 + 副标题
class HierarchyCellModel {

    let title: String?
    let detailTitle: String?

    /// 分隔线内边距
    var separatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

    init(title: String?, detailTitle: String?) {
        self.title = title
        self.detailTitle = detailTitle
    }

    /// 不显示分隔线。原版靠把 left 顶到屏幕宽度来实现，这里沿用。
    @discardableResult
    func noneInsets() -> HierarchyCellModel {
        separatorInsets = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        return self
    }
}

// MARK: - Cell Data Source

/// 本身就是一行的数据，直接喂给 cell，不再套一层适配结构
extension HierarchyCellModel: KeyValueCellDataSource {

    var detail: String? {
        detailTitle
    }

    /// 只读渲染不出尾部图标；将来做「点击复制 / 跳转」时从这里给
    var rightImage: UIImage? {
        nil
    }
}
