//
//  PerfScopeCell.swift
//  DoSwift
//

import UIKit

/// 范围条：左边永远是「开始 – 结束」，右边永远是同一个按钮。
///
/// 形状固定是有意的——它在两种范围下都长一样，读者不必辨认"现在是什么状态"，
/// 只读那两行时间。已经选中整段时按钮置灰，避免一个按了没反应的按钮。
final class PerfScopeCell: UITableViewCell {

    var onSelectAll: (() -> Void)?

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func configure(range: ClosedRange<TimeInterval>, isFull: Bool, now: TimeInterval) {
        rangeLabel.text = "\(Self.text(range.lowerBound, now: now)) – \(Self.text(range.upperBound, now: now))"
        allButton.isEnabled = !isFull
        allButton.alpha = isFull ? 0.35 : 1
    }

    /// 我们用的是单调时钟（`CACurrentMediaTime`），换算成墙上时间才能给人看
    private static func text(_ time: TimeInterval, now: TimeInterval) -> String {
        return formatter.string(from: Date(timeIntervalSinceNow: time - now))
    }

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        let row = UIStackView(arrangedSubviews: [rangeLabel, allButton])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fill
        rangeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        rangeLabel.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var rangeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private lazy var allButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("全部", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSelectAll), for: .touchUpInside)
        return button
    }()

    @objc private func handleSelectAll() {
        onSelectAll?()
    }
}
