//
//  TrendHeaderView.swift
//  DoSwift
//

import UIKit

/// 卡片顶部那一行：**指标名 + 数值 + 单位**。
///
/// 单独成 view 之后，折线区可以只认自己的 `bounds`，不必知道卡片的尺寸和内外边距。
final class TrendHeaderView: UIView {

    func render(_ chart: TrendChart?, now: TimeInterval) {
        titleLabel.text = chart?.title
        unitLabel.text = chart?.unit
        valueLabel.text = chart?.valueText(at: now)

        let alarming = chart?.isAlarming(at: now) ?? false
        valueLabel.textColor = alarming ? .systemRed : .label
        titleLabel.textColor = alarming ? .systemRed : .secondaryLabel
    }

    // MARK: - View

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        loadViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadViews() {
        // 三个优先级都显式写出来，不留并列。并列意味着「多出来的宽度给谁」是未定义的，
        // 表现就是同一份代码有时把单位紧贴在数字上、有时把它推到卡片最右。
        //
        //   标题     吃余量（hugging 低 → 由它伸长）
        //   数值块   保持固有宽度（hugging required → 不被拉长）
        //   单位     既不伸也不缩
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        valueStack.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        unitLabel.setContentHuggingPriority(.required, for: .horizontal)
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(topRow)
        topRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: topAnchor),
            topRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            topRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            topRow.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private lazy var topRow: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueStack])
        stacks.axis = .horizontal
        // 基线对齐：指标名 11pt、数值 18pt，顶对齐会让两者看起来错位
        stacks.alignment = .lastBaseline
        stacks.distribution = .fill
        return stacks
    }()

    private lazy var valueStack: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        stacks.axis = .horizontal
        stacks.alignment = .lastBaseline
        // 18pt 的数字配 9pt 的单位，3pt 看着像粘在一起
        stacks.spacing = 4
        return stacks
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    /// 等宽数字：刷新时不跳，这是它唯一的要求
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
}
