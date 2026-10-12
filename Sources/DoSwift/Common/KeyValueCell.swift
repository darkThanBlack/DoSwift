//
//  KeyValueCell.swift
//  DoSwift
//

import UIKit

/// ``KeyValueCell`` 的数据源。
///
/// 业务手上的 model 实现它即可（`update(_:)` 一把传入）；
/// 嫌麻烦就直接用 `update(title:detail:rightImage:)` 传参。
protocol KeyValueCellDataSource {

    /// 主标题（属性名）
    var title: String? { get }

    /// 副标题（属性值）。nil = 该槽位不显示
    var detail: String? { get }

    /// 尾部图标；nil = 该槽位不显示。
    ///
    /// 箭头 / 勾选 / 自定义图标都走它——一个「尾部挂了图标」的行不必单设一种 cell。
    var rightImage: UIImage? { get }
}

/// 键值行：**左侧主标题，右侧副标题**，尾部可挂一个图标。
///
/// - 结构：`H[ Title(定宽) | Detail | RightImage ]`
///
/// 刻意横排、不上下堆叠：这种行常常几十条排在一起，堆叠会把滚动长度翻一倍，
/// 而扫一眼看完全部内容正是它存在的意义。主标题**定宽**是为了让副标题的左边缘对齐成一列；
/// 副标题左对齐且可换行——`UIFont` 的 `description` 这类值很长，右对齐会从中间断开。
final class KeyValueCell: UITableViewCell {

    // MARK: - Update

    /// 数据源入口
    func update(_ dataSource: KeyValueCellDataSource?) {
        update(
            title: dataSource?.title,
            detail: dataSource?.detail,
            rightImage: dataSource?.rightImage
        )
    }

    /// 直接传参：每个参数都有默认值，只传关心的
    func update(title: String? = nil, detail: String? = nil, rightImage: UIImage? = nil) {
        titleLabel.text = title
        detailLabel.text = detail

        rightImageView.image = rightImage
        rightImageView.isHidden = (rightImage == nil)
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // 这一行本身没有交互，交互在尾部图标或整行的选中回调上
        selectionStyle = .none
        loadViews(in: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadViews(in box: UIView) {
        // 伸缩由 stack 分配：副标题吃满剩余宽度，标题与图标各自定宽
        detailLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightImageView.setContentHuggingPriority(.required, for: .horizontal)
        rightImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        stacks.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stacks)

        // 挂 `box` 的四个边，**不挂 `box.layoutMarginsGuide`**：
        // contentView 的 layoutMargins 是 UIView 的默认值（每边 8pt），UIKit 设的、
        // 本文件一个字都没写过 —— 挂 marginsGuide 等于凭空多出一圈 8pt，和下面的 16 / 8 叠加。
        NSLayoutConstraint.activate([
            stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
            stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),

            // 主标题列宽 110。显示的都是短标题，偶尔超长就让它在列内换行，
            // **不做截断**——标题被截掉一半比多一行更难用。
            titleLabel.widthAnchor.constraint(equalToConstant: 110),
        ])
    }

    private lazy var stacks: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [titleLabel, detailLabel, rightImageView])
        stacks.axis = .horizontal
        // 顶对齐：主标题换行时副标题跟着从第一行起，而不是被居中挤到一块
        stacks.alignment = .top
        stacks.distribution = .fill
        stacks.spacing = 8
        return stacks
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.isHidden = true
        return imageView
    }()
}
