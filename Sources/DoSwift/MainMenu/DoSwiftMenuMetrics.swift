//
//  DoSwiftMenuMetrics.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 主菜单面板与方块共用的度量，抽成独立类型：
/// `DoSwiftMenuPanel` 摆位置、`DoSwiftMenuTile` 算自身尺寸，两边读的是同一份数字，
/// 分开放会让「改一处忘一处」变成必然。
enum DoSwiftMenuMetrics {

    /// 一行放几个方块
    static let columns: Int = 3
    /// 面板左右内边距。方块列、分组标签、导航栏标题**共用**这一个值，
    /// 三者左边缘必须对齐——之前方块用 8、文字用 12，差 4pt，看着就是没对齐。
    static let horizontalPadding: CGFloat = 12
    /// 面板上下内边距。必须留：面板只有朝外一侧圆角 16pt，
    /// 内容贴到顶/底会被圆角切掉一块。
    static let verticalPadding: CGFloat = 10
    /// 方块之间的横向间距
    static let tileSpacing: CGFloat = 6
    static let tileWidth: CGFloat = 64
    static let tileLabelFontSize: CGFloat = 11
    static let tileIconSize: CGFloat = 24
    static let tileTopPadding: CGFloat = 8
    static let tileIconLabelGap: CGFloat = 4
    static let tileBottomPadding: CGFloat = 6

    /// 方块高度由内容推出来，不写死：改字号或图标尺寸会自动跟着变，
    /// 也保证 `DoSwiftMenuTile.sizeThatFits` 与实际排版一致。
    static let tileHeight: CGFloat = ceil(
        tileTopPadding
            + tileIconSize
            + tileIconLabelGap
            + UIFont.systemFont(ofSize: tileLabelFontSize, weight: .regular).lineHeight
            + tileBottomPadding
    )

    /// 面板宽度由列数和方块宽推出来，改 `columns` 会自动跟着变。
    /// 66 是让「沙盒浏览器」这类 5 字标题排得下的值。
    static let panelWidth: CGFloat = horizontalPadding * 2
        + tileWidth * CGFloat(columns)
        + tileSpacing * CGFloat(columns - 1)

    /// 顶部固定导航栏高度（不随内容滚动）
    static let headerBarHeight: CGFloat = 44
    /// 分组头高度（随内容滚动，会被圆角切到，所以上下留白是必须的）
    static let groupHeaderHeight: CGFloat = 28
    static let cornerRadius: CGFloat = 16
    /// 面板与安全区之间的留白
    static let verticalMargin: CGFloat = 12
    /// 面板与手柄之间的留白
    static let handleGap: CGFloat = 8
    /// 可视高度上限，超出则内部滚动
    static let maxPanelHeight: CGFloat = 420
    /// 高度下限：目录为空时也要能打开。空轨是可见症状，点不动是不可见症状。
    static let minimumPanelHeight: CGFloat = 132
    /// 关闭动画时向停靠边外侧多移一点，免得阴影露在边上
    static let shadowMargin: CGFloat = 32
    static let closeButtonSize: CGFloat = 32
    static let closeButtonSymbolSize: CGFloat = 13
}
