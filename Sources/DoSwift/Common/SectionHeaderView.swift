//
//  SectionHeaderView.swift
//  DoSwift
//

import UIKit

/// 分组表的段标题。
///
/// 样式**跟系统一致**，没有自己的设计：13pt（`.footnote`）、次级灰、不转大写
/// ——就是 `UIListContentConfiguration.groupedHeader()` 那套值，只是不用 iOS 14 的 API。
///
/// 是 `UITableViewHeaderFooterView` 而不是 `UIView`：这样它能和 cell 走同一套
/// 「按类注册 → 按 id 复用 → 约束 self sizing」，高度不必由外面写死。
final class SectionHeaderView: UITableViewHeaderFooterView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        loadViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViews()
    }

    private func loadViews() {
        contentView.addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 16pt 与 cell 内容的左右留白对齐，标题和下面的行在同一条竖线上
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // 上下留白决定 self sizing 出来的高度：16 + 一行 13pt 文字 + 8 ≈ 40
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }
}
