//
//  FileBrowserCells.swift
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

    /// 一行一格的薄壳 cell：只把 ``DO.FileRowView`` 钉满 `contentView`。
    ///
    /// 行视图是普通 `UIView`，cell 只是它在表格里的承载 —— 换承载时这里可整个替换。
    /// 自绘行视图（而不是 `.value1` / `.subtitle`）是 floor = iOS 13 时的唯一「不踩弃用」写法。
    @objc(DOFileBrowserNodeCell)
    final class FileBrowserNodeCell: UITableViewCell {

        func config(node: any DO.FileNode) {
            rowView.update(node: node)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            selectionStyle = .default
            backgroundColor = .clear
            contentView.backgroundColor = .clear

            contentView.addSubview(rowView)
            rowView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: contentView.topAnchor),
                rowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                rowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private lazy var rowView = DO.FileRowView()
    }
}
