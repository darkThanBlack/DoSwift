//
//  HierarchyDateInputView.swift
//  DoSwift
//
//  `.date` 的输入区：系统的 `UIDatePicker` + 三个快捷 chip。
//

import UIKit

/// 日期有系统控件，就是 `UIDatePicker` —— 它连 locale 也一起解决了：
/// 轮子跟随 `UIDatePicker.locale`（默认系统 locale），所以**别自己排年月日**。
///
/// 一行代码的代价换来的教训：`HierarchyFormatterTool` 用固定格式串
/// `"yyyy-MM-dd HH:mm:ss"` 却一度没有钉 locale，在泰历 / 和历 locale 下年份会显示成
/// 2569 / 1447，阿拉伯语 locale 下还会变成阿拉伯数字 —— 不报错，只是显示一个错的年份。
final class HierarchyDateInputView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)?

    private let originalDate: Date
    private var isEdited = false

    init(date: Date) {
        self.originalDate = date
        super.init(frame: .zero)
        picker.date = date
        setupSubviews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        .date(isEdited ? picker.date : originalDate)
    }

    // MARK: - Views

    private lazy var picker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime

        // `.wheels` 从 iOS 13.0 就有；`preferredDatePickerStyle` 这个属性本身是 **13.4**
        // 才有的，`.inline`（日历）要 14.0。不设的话 iOS 14+ 的 `.automatic` 会给一张
        // 展开的日历 —— 高度不定，卡片里不好摆。显式要轮子，各版本长得一样。
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
        return picker
    }()

    private func setupSubviews() {
        let chips = UIStackView(arrangedSubviews: [
            makeChip("现在", offset: 0),
            makeChip("+1 天", offset: 86_400),
            makeChip("+1 小时", offset: 3_600),
        ])
        chips.axis = .horizontal
        chips.spacing = 8

        let stack = UIStackView(arrangedSubviews: [picker, chips])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// 拖轮子挑「三天后的同一时刻」要好几下，快捷 chip 顶掉最常见的几个。
    /// 相对**现在**而不是相对当前值：想从"当前值"挪一格，轮子本来就是干这个的。
    private func makeChip(_ title: String, offset: TimeInterval) -> UIButton {
        // `UIButton.Configuration` 整个是 iOS 15 才有的 —— 分支要**先判再建**，
        // 不是建完再判：那样 13 / 14 上连 configuration 都构造不出来。
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.gray()
            configuration.title = title
            configuration.cornerStyle = .capsule
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            return UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
                self?.applyOffset(offset)
            })
        }

        let legacy = UIButton(type: .system)
        legacy.setTitle(title, for: .normal)
        legacy.titleLabel?.font = .systemFont(ofSize: 14)
        legacy.backgroundColor = .tertiarySystemFill
        legacy.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        legacy.layer.cornerRadius = 14
        legacy.tag = Int(offset)
        legacy.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return legacy
    }

    private func applyOffset(_ offset: TimeInterval) {
        picker.setDate(Date().addingTimeInterval(offset), animated: true)
        pickerChanged()
    }

    @objc private func chipTapped(_ sender: UIButton) {
        applyOffset(TimeInterval(sender.tag))
    }

    @objc private func pickerChanged() {
        isEdited = true
        onValidityChange?(true)
    }
}
