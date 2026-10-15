//
//  HierarchyNumberGridView.swift
//  DoSwift
//
//  `.size` / `.point` / `.insets` 共用的输入区：N 个分量，每个是一行「字段名 + 数字输入」。
//

import UIKit

/// 三种几何类型交互完全同构 —— 都是"填 N 个数字"，差的只是 N 和字段名。
/// 所以是一个组件带一个字段名数组，不是三套 UI。
///
/// **一行一个分量，不是两列网格**：每格都要带 `UIStepper`（`UIStepper` 固有宽度约 94pt），
/// 塞进两列里每列只剩 160pt，字段会被挤到读不下 `16` 这种两位数。
/// 竖排之后每一格都是完整的「字段名 + 输入 + 步进」，也就是**直接复用数字输入那一个组件**。
final class HierarchyNumberGridView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)?

    private let fields: [HierarchyNumberFieldView]
    private let compose: ([Double]) -> ValueKind

    init(labels: [String], values: [Double], compose: @escaping ([Double]) -> ValueKind) {
        self.compose = compose
        // 步长给 1：这几个分量是点值，实践中都是整数。小数要更细的时候手打即可。
        self.fields = values.map {
            HierarchyNumberFieldView(isInteger: false, step: 1, value: $0, prominent: false)
        }
        super.init(frame: .zero)
        setupSubviews(labels: labels)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        guard let numbers = currentValues() else { return nil }
        return compose(numbers)
    }

    // MARK: - Views

    private func setupSubviews(labels: [String]) {
        let rows: [UIView] = zip(labels, fields).map { label, field in
            let name = HierarchyEditorStyle.makeLabel(label)
            name.setContentHuggingPriority(.required, for: .horizontal)
            name.setContentCompressionResistancePriority(.required, for: .horizontal)

            let row = UIStackView(arrangedSubviews: [name, field])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12

            // 字段名一栏对齐成一条线：`width` / `height` 宽度不同，不钉住的话输入框会参差
            name.widthAnchor.constraint(equalToConstant: 64).isActive = true
            return row
        }

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = HierarchyEditorStyle.rowGap

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for field in fields {
            field.onValueChanged = { [weak self] in self?.changed() }
            field.onValidityChange = { [weak self] _ in self?.changed() }
        }
    }

    // MARK: - Value

    private func currentValues() -> [Double]? {
        var numbers: [Double] = []
        for field in fields {
            guard case let .double(number)? = field.readValue() else { return nil }
            numbers.append(number)
        }
        return numbers
    }

    private func changed() {
        let values = currentValues()
        onValidityChange?(values != nil)
    }

}
