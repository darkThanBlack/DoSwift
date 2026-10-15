//
//  HierarchyEnumListView.swift
//  DoSwift
//
//  `.enumValue` 的输入区：单列列表，当前项打勾。
//

import UIKit

/// 用 `UIScrollView` + `UIStackView` 排，**不是 `UITableView`** —— 最多十几行，
/// 不需要复用和代理那一套。滚动交给卡片自己的滚动视图（嵌套两层滚动只会打架）。
///
/// 不用系统的 action sheet：那个本来就能用，但它会把 39 行里的这一类挪出卡片，
/// 容器就不是同一个了；而且它画勾得靠 KVC 往 `UIAlertAction` 塞 `image` ——
/// 私有布局，随系统版本漂。
final class HierarchyEnumListView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)? {
        didSet { onValidityChange?(selectedIndex != nil) }
    }

    private let table: String
    private let names: [String]
    private let rawValues: [Int]
    private var selectedIndex: Int?
    private var checkmarks: [UILabel] = []

    /// 表查不到（或表是空的）就造不出来 —— 返回 nil，卡片干脆不弹，
    /// 好过弹一张空白的、还点不了「完成」的卡片。
    init?(table: String, currentRawValue: Int) {
        self.table = table
        let options = HierarchyPropertyEngine.shared
            .enumOptions(for: table, currentRawValue: currentRawValue)
        guard !options.names.isEmpty else { return nil }
        self.names = options.names
        self.rawValues = options.rawValues
        // 当前值不在表里（比如位掩码值）就一个都不勾，逼用户挑一个 ——
        // 空着比乱指一个更诚实
        self.selectedIndex = options.currentIndex
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        guard let index = selectedIndex, rawValues.indices.contains(index) else { return nil }
        return .enumValue(raw: rawValues[index], table: table, name: names[index])
    }

    // MARK: - Views

    private func setupSubviews() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0

        for (index, name) in names.enumerated() {
            if index > 0 { stack.addArrangedSubview(makeSeparator()) }
            stack.addArrangedSubview(makeRow(index: index, name: name))
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        refreshCheckmarks()
    }

    private func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return line
    }

    private func makeRow(index: Int, name: String) -> UIControl {
        // 勾留在**原位**、也不禁用这一行 —— action sheet 当年是靠"禁用当前项"来表示
        // "选过了"，结果是当前项点不回去（想重选同一项只能取消再来一次）。
        let check = UILabel()
        check.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        check.textColor = .systemBlue
        check.text = "✓"
        checkmarks.append(check)

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        nameLabel.numberOfLines = 0

        let rawLabel = UILabel()
        rawLabel.text = "\(rawValues[index])"
        rawLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        rawLabel.textColor = .secondaryLabel
        rawLabel.setContentHuggingPriority(.required, for: .horizontal)
        rawLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = UIStackView(arrangedSubviews: [check, nameLabel, rawLabel])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 10
        content.isUserInteractionEnabled = false

        let row = EnumRowView()
        row.tag = index
        row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
        row.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 11),
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -11),
            check.widthAnchor.constraint(equalToConstant: 16),
        ])
        return row
    }

    private func refreshCheckmarks() {
        for (index, check) in checkmarks.enumerated() {
            check.alpha = index == selectedIndex ? 1 : 0
        }
    }

    // MARK: - Actions

    @objc private func rowTapped(_ row: UIControl) {
        selectedIndex = row.tag
        refreshCheckmarks()
        onValidityChange?(true)
    }
}

// MARK: -

/// 一行。按下时给点反馈 —— 它长得不像按钮（没有边框），不给反馈就像点在了空处。
private final class EnumRowView: UIControl {

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .tertiarySystemFill : .clear }
    }
}
