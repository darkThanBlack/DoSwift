//
//  ActionCell.swift
//  DoSwift
//

import UIKit

/// 整行就是一个动作的行：文字居中，点一下执行，没有开关也没有箭头。
///
/// 系统设置里「退出登录」那类行就是这个形态。分成独立一种 cell 而不是复用
/// `KeyValueCell`：那一类的标题是**定宽左对齐**的键，这里的字是**居中**的动作，
/// 两者排法相反，硬塞进同一个 cell 只会多一个开关。
final class ActionCell: UITableViewCell, SectionCell {

    // MARK: - Output

    weak var sectionDelegate: SectionCellDelegate?

    // MARK: - Update

    /// - Parameter isDestructive: 危险动作用 `systemRed`
    func update(title: String?, isDestructive: Bool = false) {
        titleLabel.text = title
        // `UIColor.tintColor` 是 iOS 15+，这里取 cell 自己的 tintColor
        titleLabel.textColor = isDestructive ? .systemRed : tintColor
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .default
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        guard selected else { return }
        sectionDelegate?.sectionCellDidTrigger(self)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .center
        return label
    }()
}
