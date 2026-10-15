//
//  HierarchyColorPanelView.swift
//  DoSwift
//
//  `.color` 的输入区：预览块 + 一个合一输入框 + Alpha 滑杆。
//

import UIKit

/// 纯自绘。**系统取色器不做**（它是 iOS 14+，而且会把整页挪到系统面板里去），
/// **系统色板也先不做** —— 那 8 个点要么写死 hex 把动态色变成静态色，
/// 要么就得让输入框认识色名，两条都还没到时候。
///
/// 输入框只认 sRGB 的四种写法（引擎的 `hierarchy_color(from:)` 本来就全认识）。
/// 代价写在明处：原值若是 `displayP3` 或动态系统色，读出来那串已经把色域压平了 ——
/// **编辑一次就变成 sRGB**。这是自绘换来的确定性。
final class HierarchyColorPanelView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)?

    /// 要写回去的颜色。**没被编辑过就还是原来那个对象**，不经过 hex 往返。
    private var pending: UIColor

    init(color: UIColor) {
        self.pending = color
        super.init(frame: .zero)
        setupSubviews()

        field.text = color.hierarchy_editableText
        alphaSlider.value = Float(color.hierarchy_alpha)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        syncPendingFromField() ? .color(pending) : nil
    }

    // MARK: - Views

    private lazy var swatch: UIView = {
        let view = UIView()
        view.layer.cornerRadius = HierarchyEditorStyle.fieldRadius
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.layer.borderColor = UIColor.separator.cgColor
        view.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return view
    }()

    private lazy var field: UITextField = {
        let field = UITextField()
        field.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        field.backgroundColor = HierarchyEditorStyle.fieldBackground
        field.layer.cornerRadius = HierarchyEditorStyle.fieldRadius
        field.layer.masksToBounds = true
        field.borderStyle = .none
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // 颜色是可以粘的：不许系统把 `#` 变成 `＃`、把引号掰弯
        HierarchyEditorStyle.disableSmartInput(field)
        field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return field
    }()

    private lazy var alphaSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        // **这里能有 slider，而 `.double` 不能**：`.double` 的范围不可推导、JSON 也不声明，
        // 没有范围就画不出有意义的滑杆；alpha 的 0–1 是颜色的定义本身，不是声明出来的。
        slider.isContinuous = false   // 松手才回报一次，途中不必反复改值
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return slider
    }()

    private lazy var hintLabel: UILabel = {
        let label = HierarchyEditorStyle.makeLabel("也收 r,g,b,a · #RRGGBBAA")
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .tertiaryLabel
        return label
    }()

    private func setupSubviews() {
        let alphaLabel = HierarchyEditorStyle.makeLabel("alpha")
        let alphaRow = UIStackView(arrangedSubviews: [alphaLabel, alphaSlider])
        alphaRow.axis = .horizontal
        alphaRow.alignment = .center
        alphaRow.spacing = 12
        alphaLabel.widthAnchor.constraint(equalToConstant: 64).isActive = true

        let stack = UIStackView(arrangedSubviews: [swatch, field, hintLabel, alphaRow])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(4, after: field)

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
        guard syncPendingFromField() else {
            onValidityChange?(false)
            return
        }
        // 字段是唯一真相：它写了 alpha，滑杆就跟着走
        alphaSlider.value = Float(pending.hierarchy_alpha)
        refresh()
        onValidityChange?(true)
    }

    @objc private func sliderChanged() {
        // 滑杆也回写字段 —— 两个控件改的是同一个值，只让一边动就会互相骗。
        // 一律写成**带 alpha 的八位**，这样字段文本和滑杆永远对得上。
        pending = pending.withAlphaComponent(CGFloat(alphaSlider.value))
        field.text = pending.hierarchy_editableText
        refresh()
    }

    // MARK: - Value

    /// 把字段里的字同步成 `pending`。
    ///
    /// 是**解析**不是校验：输入框是这个页面的唯一真相，所以读值这一步必然带副作用
    /// （读的过程就是认定它）。叫得出名字的方法比一个会改状态的 `fieldIsValid` 属性诚实。
    private func syncPendingFromField() -> Bool {
        guard let text = field.text, let parsed = UIColor.hierarchy_color(from: text) else { return false }
        pending = parsed
        return true
    }

    private func refresh() {
        swatch.backgroundColor = pending
    }
}
