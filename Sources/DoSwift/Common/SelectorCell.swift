//
//  SelectorCell.swift
//  DoSwift
//

import UIKit

/// ``SelectorCell`` 的数据源。
///
/// 与 `ToggleCellDataSource` 同理，两项都非可选。
protocol SelectorCellDataSource {

    /// 主标题
    var title: String { get }

    /// 副标题。放**当前取值**最有用——一眼能看到状态，比再写一遍说明强
    var detail: String { get }
}

/// 选择行：左侧「标题 + 当前值」竖排，右侧一个箭头。
///
/// - 结构：`H[ V[Title, Detail] | Chevron ]`
///
/// 与 `ToggleCell` 同构，只把开关换成箭头。两者的事件走同一条路
/// （`SectionCellDelegate`），区别只在触发时机：一个在拨动开关时，一个在整行被点时。
/// 两者刻意**不互相继承**：共用的只有一组字号常量，而那点东西复制一遍比多一层继承清楚。
///
/// 结构上与 `KeyValueCell` 也只是排法不同（竖排 vs 横排），
/// 但那点差别不足以让一个 cell 长出「哪种排法」的开关。
final class SelectorCell: UITableViewCell, SectionCell {

    // MARK: - Output

    /// 事件出口。谁持有这张表谁就是代理，由 `SectionTableViewController` 接上。
    weak var sectionDelegate: SectionCellDelegate?

    /// 副标题最多显示几行。0 = 不限。
    ///
    /// 默认不限：配置页那种一句说明常常要写满一行。要「单行摘要 + 下钻看全文」的列表
    /// （UserDefaults 浏览器）在调用点显式传 1。
    var detailNumberOfLines: Int = 0 {
        didSet { detailLabel.numberOfLines = detailNumberOfLines }
    }

    /// 主标题最多显示几行。0 = 不限。
    ///
    /// 与 `detailNumberOfLines` 对称。默认不限（配置页的标题都短）；日志那种
    /// 「一行正文 + 下钻看全文」的列表在调用点显式传 1，行高才整齐。
    var titleNumberOfLines: Int = 0 {
        didSet { titleLabel.numberOfLines = titleNumberOfLines }
    }

    // MARK: - Update

    /// 数据源入口
    func update(_ dataSource: SelectorCellDataSource?) {
        update(
            title: dataSource?.title,
            detail: dataSource?.detail
        )
    }

    /// 直接传参：每个参数都有默认值，只传关心的
    func update(title: String? = nil, detail: String? = nil) {
        titleLabel.text = title
        detailLabel.text = detail
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // 整行可点，所以保留系统的选中高亮；箭头自己画，不用 accessory
        selectionStyle = .default
        loadViews(in: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadViews(in box: UIView) {
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.setContentCompressionResistancePriority(.required, for: .horizontal)

        stacks.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stacks)

        // 同 `KeyValueCell`：直接挂 `box` 的边，不走 `box.layoutMarginsGuide`
        // （contentView 的 layoutMargins 默认每边 8pt，会再叠一圈）
        NSLayoutConstraint.activate([
            stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
            stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
        ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // 事件从这里发出，而不是表代理的 `didSelectRowAt`：整行被点只是这一格的一种事件，
        // 由 cell 自己发，往后多出别的事件时，表那边一行都不用改
        guard selected else { return }
        sectionDelegate?.sectionCellDidTrigger(self)
    }

    private lazy var stacks: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [textStack, chevronView])
        stacks.axis = .horizontal
        stacks.alignment = .center
        stacks.spacing = 8
        return stacks
    }()

    private lazy var textStack: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stacks.axis = .vertical
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

    /// 自己放箭头而不用 `accessoryType = .disclosureIndicator`：
    /// 与 `ToggleCell` 保持同一套约束，两行的排版才对得上
    private lazy var chevronView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()
}
