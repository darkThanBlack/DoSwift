//
//  TrendTextView.swift
//  DoSwift
//

import UIKit

/// 单行文字的渲染器：**一次显示全部指标**。
///
/// 与折线图并列的另一种展示形式，读的是同一批序列。它比折线图多做了一件事——
/// 一行里放下三个数；少做了一件事——丢掉趋势形状。所以它一次只取每个源的最后一个点，
/// 不需要窗口，也不需要绘制。
///
/// 背景由外层的卡片负责（它要知道该不该给整块上色），这里只管文字。
final class TrendTextView: UIView {

    private enum Metrics {
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 6
    }

    /// 分隔符。用 `·` 而不是竖线：后者在这个尺寸下太重
    private static let separator = "  ·  "

    /// 把数值替换成等宽的占位符再量一次得到的宽度。
    ///
    /// 没有它，数字位数一变（60 → 58、3 → 12）整条 pill 就跟着呼吸一次，
    /// 每秒抖一下比折线图那种固定矩形烦人得多。
    private var reservedWidth: CGFloat = 0

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: Metrics.horizontalPadding, dy: Metrics.verticalPadding)
    }

    // MARK: - Render

    func render(_ charts: [TrendChart], now: TimeInterval) {
        label.attributedText = text(for: charts, now: now, placeholder: false)
        reservedWidth = text(for: charts, now: now, placeholder: true).size().width
        setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize { sizeThatFits(.zero) }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let content = max(label.intrinsicContentSize.width, reservedWidth)
        return CGSize(
            width: content + Metrics.horizontalPadding * 2,
            height: label.intrinsicContentSize.height + Metrics.verticalPadding * 2
        )
    }

    // MARK: - Private

    /// - Parameter placeholder: 为真时把所有数值换成 `888`，用来量一个不随数值变动的宽度。
    private func text(for charts: [TrendChart], now: TimeInterval, placeholder: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let name: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.62),
        ]
        let number: [NSAttributedString.Key: Any] = [
            // 等宽数字：刷新时不跳
            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.95),
        ]

        for (index, chart) in charts.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: Self.separator, attributes: name))
            }
            result.append(NSAttributedString(string: chart.title + " ", attributes: name))

            let value = placeholder ? "888" : chart.valueText(at: now)
            result.append(NSAttributedString(string: value, attributes: number))

            if !chart.unit.isEmpty {
                result.append(NSAttributedString(string: " " + chart.unit, attributes: name))
            }
        }
        return result
    }
}
