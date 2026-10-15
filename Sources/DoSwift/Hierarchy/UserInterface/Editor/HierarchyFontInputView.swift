//
//  HierarchyFontInputView.swift
//  DoSwift
//
//  `.font` 的输入区：一行实渲预览 + 一个字号数字输入。
//

import UIKit

/// 字体比别的类型多一样东西 —— **预览**。字号是看不见摸不着的数字，
/// 而这一行字就是用当前字体画出来的，改字号它自己会变。
///
/// 只动字号：沿用原版 `[font fontWithSize:]` 的语义，**保留字体族**。
/// 字体族是另一个轴，要写整个 `UIFont` 才动得了，而 `parsed` 现在只认字号 ——
/// `UIFontPickerViewController` 只给 family/face 不给 size，两个轴凑一个面板反而更绕。
/// 那部分放后面。
final class HierarchyFontInputView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)? {
        didSet { onValidityChange?(readValue() != nil) }
    }

    private let originalFont: UIFont
    private lazy var field = HierarchyNumberFieldView(isInteger: false, step: 0.5,
                                                      value: Double(originalFont.pointSize))

    init(font: UIFont) {
        self.originalFont = font
        super.init(frame: .zero)
        setupSubviews()
        refreshPreview()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        guard case let .double(size)? = field.readValue() else { return nil }
        return .font(originalFont.withSize(CGFloat(size)))
    }

    // MARK: - Views

    private lazy var preview: UILabel = {
        let label = UILabel()
        label.text = "The quick brown fox 字体预览"
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    private func setupSubviews() {
        let stack = UIStackView(arrangedSubviews: [preview, field])
        stack.axis = .vertical
        stack.spacing = 14

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        field.onValueChanged = { [weak self] in self?.refreshPreview() }
        field.onValidityChange = { [weak self] isValid in self?.onValidityChange?(isValid) }
    }

    private func refreshPreview() {
        guard case let .double(size)? = field.readValue(), size > 0 else { return }
        preview.font = originalFont.withSize(CGFloat(size))
    }
}
