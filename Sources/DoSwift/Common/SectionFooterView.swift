//
//  SectionFooterView.swift
//  DoSwift
//

import UIKit

/// 分组表的段脚注。与 `SectionHeaderView` 同一套字号 / 颜色 / 复用方式，
/// 只是上下留白的比例反过来——脚注贴着它上面那一段，与下一段之间留出间距。
final class SectionFooterView: UITableViewHeaderFooterView {

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
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
}
