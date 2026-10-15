//
//  HierarchyNumberFieldView.swift
//  DoSwift
//
//  数字输入：一个等宽字段 + 一个系统 `UIStepper`。
//

import UIKit

/// `.int` / `.double` / 数字格里的每一格，用的都是它 —— 差别只有 `isInteger` 和 `step`。
///
/// **没有 slider**：范围不可推导，而 JSON 不声明范围。唯一的例外是字号的 1–100 和
/// 颜色 alpha 的 0–1，那两个是类型自带的边界，各自在那边说明。
final class HierarchyNumberFieldView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)? {
        didSet { onValidityChange?(readValue() != nil) }
    }

    /// 值变了。数字格靠它刷新回执。
    var onValueChanged: (() -> Void)?

    private let isInteger: Bool

    /// 初始值原样留着。**没被编辑过就写回它本身** —— 否则显示成两位小数再解析回来，
    /// `0.333` 会悄悄变成 `0.33`，而用户什么都没动。
    private let originalValue: Double
    private var isEdited = false

    init(isInteger: Bool, step: Double, value: Double, prominent: Bool = true) {
        self.isInteger = isInteger
        self.originalValue = value
        super.init(frame: .zero)

        field.text = Self.text(for: value, isInteger: isInteger)
        field.font = prominent ? HierarchyEditorStyle.prominentValueFont
                               : HierarchyEditorStyle.valueFont
        // 高度要显式给：`UITextField` 的固有高度只有一行字那么高（约 20pt），
        // 而旁边的步进器是 32pt —— 不给的话输入框会是一条细带子
        fieldHeight.constant = prominent ? 60 : 40

        // 步进的基准是**字段里现在这个值**，不是 stepper 自己攒的状态：
        // 用户手打完一个数再点加减，应该从手打的那个数开始走。
        stepper.minimumValue = -Self.stepperBound
        stepper.maximumValue = Self.stepperBound
        stepper.stepValue = step
        stepper.value = value

        setupSubviews()
        fieldHeight.isActive = true
        updateValidity()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        guard let number = currentValue() else { return nil }
        return isInteger ? .int(Int(number)) : .double(number)
    }

    // MARK: - Views

    private lazy var fieldHeight = field.heightAnchor.constraint(equalToConstant: 40)

    private lazy var field: UITextField = {
        let field = UITextField()
        field.font = HierarchyEditorStyle.valueFont
        field.textAlignment = .center
        field.backgroundColor = HierarchyEditorStyle.fieldBackground
        field.layer.cornerRadius = HierarchyEditorStyle.fieldRadius
        field.layer.masksToBounds = true
        field.borderStyle = .none

        // `.numberPad` 上没有负号 —— `tag = -1`、`selectedSegmentIndex = -1`（未选中）
        // 都打不出来，而那正是整型最常改的两个值。
        field.keyboardType = isInteger ? .numbersAndPunctuation : .decimalPad
        HierarchyEditorStyle.disableSmartInput(field)
        field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return field
    }()

    private lazy var stepper: UIStepper = {
        let stepper = UIStepper()
        // `minimumValue` / `maximumValue` 默认是 0 / 100，而且 `value` 会被**静默 clamp**
        // 到这两个边界 —— 不放开的话 `tag` 加到 100 就不动了，还不报错。
        // 用 ±1e15 而不是 `Double(Int.max)`：1e15 还在 Double 精确表示整数的范围内。
        stepper.autorepeat = true
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        return stepper
    }()

    private static let stepperBound = 1e15

    private func setupSubviews() {
        let stack = UIStackView(arrangedSubviews: [field, stepper])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func fieldChanged() {
        isEdited = true
        // 字段是唯一真相：能解析就把 stepper 拉过来对齐，解析不了就让它停在最后一个好值上
        if let number = parsedNumber() { stepper.value = number }
        updateValidity()
        onValueChanged?()
    }

    @objc private func stepperChanged() {
        isEdited = true
        field.text = Self.text(for: stepper.value, isInteger: isInteger)
        updateValidity()
        onValueChanged?()
    }

    // MARK: - Value

    /// 字段里现在是不是一个合法的数。整型走 `Int` 而不是 `Double`：
    /// `"3.7"` 对 `Int` 是 nil（描红），对 `Double` 是 3.7（会被悄悄截成 3）——
    /// 那正是原版 `integerValue` 的老毛病。
    private func parsedNumber() -> Double? {
        guard let text = field.text, !text.isEmpty else { return nil }
        return isInteger ? Int(text).map(Double.init) : Double(text)
    }

    private func updateValidity() {
        onValidityChange?(parsedNumber() != nil)
    }

    /// 读值：**没编辑过就把原值本身交出去**，不经过字符串。
    /// 否则 `0.333` 显示成 `0.33` 再解析回来，用户什么都没动，值却变了。
    private func currentValue() -> Double? {
        guard parsedNumber() != nil else { return nil }
        return isEdited ? parsedNumber() : originalValue
    }

    private static func text(for value: Double, isInteger: Bool) -> String {
        isInteger ? "\(Int(value))" : HierarchyFormatterTool.format(NSNumber(value: value))
    }
}
