//
//  SectionCell.swift
//  DoSwift
//

import UIKit

/// 表里 cell 的统一事件出口。
///
/// 方法是通用的 `trigger` 而不是 `didSelect`：**「整行被点」只是 cell 可能发出的
/// 一种事件**，往后完全可能多出别的（长按、侧滑……）。到那天在这里加一个带载荷的
/// 重载即可，不必让每个 cell 各造一套 delegate 协议，也不必让表去猜是哪一种。
/// 当前每个 cell 都只有一种事件，所以先只留这一个。
///
/// 事件**不带值**：值就在 cell 上（比如 `ToggleCell.isOn`），谁需要谁读。
/// 让 cell 带着值走，等于逼每个 cell 在协议里长出自己专属的方法签名。
protocol SectionCellDelegate: AnyObject {

    /// 这一格被「动了」。具体是什么意思由 cell 自己定义。
    func sectionCellDidTrigger(_ cell: UITableViewCell)
}

/// 表里 cell 的统一形态：事件从 `sectionDelegate` 出去。
///
/// 有它，表才能不认识具体 cell 类型就把自己接成代理；没它的 cell（纯只读行）
/// 就是不可交互的，表也不会给它接事件。
protocol SectionCell: AnyObject {

    var sectionDelegate: SectionCellDelegate? { get set }
}
