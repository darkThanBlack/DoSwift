//
//  ToggleCell.swift
//  DoSwift
//

import UIKit

/// ``ToggleCell`` 的数据源。
///
/// 三项都非可选：开关行的标题和说明总要写，缺省没有意义——**写成可选反而害得
/// 业务侧的现成 model 无法直接适配**（Swift 里 `String` 不能作为 `String?` 的见证）。
/// 真要只填一部分，走下面那个每个参数都有默认值的传参入口。
protocol ToggleCellDataSource {

    /// 主标题
    var title: String { get }

    /// 副标题
    var detail: String { get }

    /// 开关状态
    var isOn: Bool { get }
}

/// 开关行：左侧「标题 + 副标题」竖排，右侧 `UISwitch`。
///
/// - 结构：`H[ V[Title, Detail] | Switch ]`
///
/// 与 `KeyValueCell` 的横排不同，这里竖排：主标题和说明都短，
/// 但说明常常要写满一行，横排会把右侧挤掉。竖排也正是系统 `.subtitle` cell 的排法，
/// 本类是它的替代品，行高与留白按同一套数值来。
final class ToggleCell: UITableViewCell, SectionCell {

    // MARK: - Output

    /// 事件出口。谁持有这张表谁就是代理，由 `SectionTableViewController` 接上。
    weak var sectionDelegate: SectionCellDelegate?

    /// 开关此刻的状态。
    ///
    /// 事件本身**不带值**（见 `SectionCellDelegate`），要值的人从这里读——
    /// 「这一格被动了」是统一的事件，动成了什么样是这个 cell 自己的属性。
    var isOn: Bool {
        swit.isOn
    }

    // MARK: - Update

    /// 数据源入口
    func update(_ dataSource: ToggleCellDataSource?) {
        update(
            title: dataSource?.title,
            detail: dataSource?.detail,
            isOn: dataSource?.isOn ?? false
        )
    }

    /// 直接传参：每个参数都有默认值，只传关心的
    func update(title: String? = nil, detail: String? = nil, isOn: Bool = false) {
        titleLabel.text = title
        detailLabel.text = detail

        swit.setOn(isOn, animated: false)
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // 整行的点击不做任何事，交互只有那个开关
        selectionStyle = .none
        loadViews(in: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadViews(in box: UIView) {
        // 文字吃满剩余宽度后换行，不去挤开关
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        swit.setContentHuggingPriority(.required, for: .horizontal)
        swit.setContentCompressionResistancePriority(.required, for: .horizontal)

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

    @objc private func switchChanged(_ sender: UISwitch) {
        // cell 自己不落地任何状态，改哪儿由外面决定
        sectionDelegate?.sectionCellDidTrigger(self)
    }

    private lazy var stacks: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [textStack, swit])
        stacks.axis = .horizontal
        // 开关在竖直方向居中，跟两行文字整体对齐
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

    private lazy var swit: UISwitch = {
        let swit = UISwitch()
        swit.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        return swit
    }()
}
