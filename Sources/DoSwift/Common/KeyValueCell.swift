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

/// 键值行：左侧「标题 + 值」竖排，尾部可挂一个图标。
///
/// - 结构：`H[ V[Title, Detail] | RightImage ]`
///
/// 与 `SelectorCell` 同构，只把箭头换成可选图标；字号、行距、留白是同一套数值，
/// 所以两者排在一张表里对得齐。
///
/// 竖排而不是横排：值这一侧常常比标题长得多（`UIFont` 的 `description`、颜色 hex）
/// 而标题都短，横排要么按标题宽度切一刀、让值从中间断开，要么把它压成一条窄柱。
/// 竖排让值吃满整行宽，长值只往下长，横排省下的那点高度远不值得。
///
/// 它**也发事件**（`SectionCell`）：这一行的交互历来就有——尾部图标、或者整行被点
/// ——只是以前没人从这一格往外报。事件照走 `SectionCellDelegate` 那条路，
/// 于是「点一下这一行要做什么」由调用方在 `Row(onTrigger:)` 里给，不必新造一种 cell。
final class KeyValueCell: UITableViewCell, SectionCell {

    // MARK: - Output

    /// 事件出口。谁持有这张表谁就是代理，由 `SectionTableViewController` 接上。
    weak var sectionDelegate: SectionCellDelegate?

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

        // 默认不给选中高亮：多数调用点（属性检查器）只是看，行不可交互。
        // 可交互的调用点在 `configure` 里显式改回 `.default`——高亮就是那一点反馈，
        // 而「这一行能不能点」在调用点比在这里更好看出来。
        selectionStyle = .none
        loadViews(in: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // 事件从这里发出，而不是表代理的 `didSelectRowAt`：整行被点只是这一格的一种事件，
        // 与 `SelectorCell` / `ToggleCell` 走同一条路
        guard selected else { return }
        sectionDelegate?.sectionCellDidTrigger(self)
    }

    private func loadViews(in box: UIView) {
        // 逐项同 `SelectorCell`：文字吃满剩余宽度后换行，尾部图标定宽
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // 图标为 nil 时整体从布局里退出（stack 会跳过隐藏项），文字自动拿满宽度；
        // 所以要的只是「有图标时就定宽」，不必额外加一条宽度约束
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
        ])
    }

    private lazy var stacks: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [textStack, rightImageView])
        stacks.axis = .horizontal
        // 图标在竖直方向居中，跟两行文字整体对齐
        stacks.alignment = .center
        stacks.spacing = 8
        return stacks
    }()

    private lazy var textStack: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stacks.axis = .vertical
        // 左对齐：值比标题长时从标题的左边缘起，不居中
        stacks.alignment = .leading
        stacks.spacing = 2.0
        return stacks
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        // 字号 / 颜色与系统 `.subtitle` cell 一致
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
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
