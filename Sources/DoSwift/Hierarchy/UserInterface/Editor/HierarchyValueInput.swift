//
//  HierarchyValueInput.swift
//  DoSwift
//
//  属性编辑卡片中间那块「输入区」的契约，以及按类型造它的工厂。
//

import UIKit

/// 卡片中间那块输入区。
///
/// 对外只有三件事：
///   * **填初值** —— 各实现的 `init` 收一个 `ValueKind`，卡片不用管细节
///   * **报合不合法** —— `onValidityChange`，卡片据此开关「完成」
///   * **读值** —— `readValue()`，不合法返回 nil
///
/// **值就是 `ValueKind`，不经过字符串**：日期轮产出 `Date`、色板产出 `UIColor`、
/// 数字格产出 `CGSize` —— 让它们先格式化成文本再解析回来是白绕一圈，
/// 颜色还会在 hex 往返里换掉色彩空间。只有真的靠打字输入的类型，
/// 内部才用引擎的 `parsed` 判合法性。
protocol HierarchyValueInput: UIView {

    /// 合法性变了。卡片据此开关「完成」。
    var onValidityChange: ((Bool) -> Void)? { get set }

    /// 当前输入对应的值。不合法时返回 `nil`。
    func readValue() -> ValueKind?
}

/// 按类型造输入区。
///
/// 返回 `nil` 表示这个类型还没有输入区 —— 和引擎 `canEdit` 为 false 的那几种一一对应。
/// `bool` 也走不到这里：它由行内开关直接处理，压根不弹卡片。
enum HierarchyValueInputFactory {

    static func make(for kind: ValueKind) -> HierarchyValueInput? {
        switch kind {
        case .text(let text):
            return HierarchyMultilineTextView(text: text)

        case .int(let value):
            return HierarchyNumberFieldView(isInteger: true, step: 1, value: Double(value))

        case .double(let value):
            return HierarchyNumberFieldView(isInteger: false, step: 0.1, value: value)

        case .enumValue(let raw, let table, _):
            return HierarchyEnumListView(table: table, currentRawValue: raw)

        case .font(let font):
            return HierarchyFontInputView(font: font)

        case .color(let color):
            return HierarchyColorPanelView(color: color)

        case .date(let date):
            return HierarchyDateInputView(date: date)

        case .size(let size):
            // 分量名用结构体原名、顺序也是结构体顺序 —— 不用用户记 CGSize 谁是宽
            return HierarchyNumberGridView(labels: ["width", "height"],
                                           values: [Double(size.width), Double(size.height)]) {
                .size(CGSize(width: $0[0], height: $0[1]))
            }

        case .point(let point):
            return HierarchyNumberGridView(labels: ["x", "y"],
                                           values: [Double(point.x), Double(point.y)]) {
                .point(CGPoint(x: $0[0], y: $0[1]))
            }

        case .insets(let insets):
            return HierarchyNumberGridView(labels: ["top", "left", "bottom", "right"],
                                           values: [Double(insets.top), Double(insets.left),
                                                    Double(insets.bottom), Double(insets.right)]) {
                .insets(UIEdgeInsets(top: $0[0], left: $0[1], bottom: $0[2], right: $0[3]))
            }

        case .bool, .image, .attributedText, .frame, .unknown:
            return nil
        }
    }
}

// MARK: - 共用样式

/// 编辑卡片里的共用尺寸与颜色。放在一处，免得六个组件各自长出一套。
enum HierarchyEditorStyle {

    static let padding: CGFloat = 20
    static let rowGap: CGFloat = 14

    /// 输入框的底 —— 系统填充色，和 `insetGrouped` 表里的表单一个观感
    static let fieldBackground = UIColor.secondarySystemFill
    static let fieldRadius: CGFloat = 10

    static let labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let bodyFont = UIFont.systemFont(ofSize: 17)
    static let valueFont = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
    static let prominentValueFont = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: .semibold)

    /// 字段名。小写、等宽 —— 它们是结构体的成员名，不是给人读的句子。
    static func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }

    /// 打字类输入一律关掉的智能修正。
    ///
    /// 改的是**源代码里的字面量**，不是给人读的句子 —— 系统的大写、弯引号、
    /// 自动纠错在这里全是破坏。这一整套 `hierarchy_showTextFieldAlert` 当年一个都没关，
    /// 打 `hello world` 进去写出来是 `Hello world`，而用户看不见这个过程。
    /// 两个重载而不是收 `UITextInputTraits` 存在类型：`UITextField` 和 `UITextView`
    /// 都兑现这个协议，但隔着存在类型改属性值会多绕一层，收益是零。
    static func disableSmartInput(_ field: UITextField) {
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.textContentType = nil
    }

    static func disableSmartInput(_ view: UITextView) {
        view.autocapitalizationType = .none
        view.autocorrectionType = .no
        view.spellCheckingType = .no
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.textContentType = nil
    }
}
