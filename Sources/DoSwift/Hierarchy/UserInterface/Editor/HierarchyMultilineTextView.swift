//
//  HierarchyMultilineTextView.swift
//  DoSwift
//

import UIKit

/// `.text` 的输入区：一个多行 `UITextView`。
///
/// 字面量就是值本身，所以这里没有类型转换 —— 只有两件事要做对：**别让系统替你改字**，
/// 以及**别去算高度**。
///
/// 高度写死。`UITextView` 在内容超出自身时本来就会内部滚动，"按行数算高度"换来的
/// 只是"卡片能矮一点"，代价却是一堆边角：宽度还没解析出来时算不出行高（`sizeThatFits`
/// 会按每个字折行，得到一个假的高度）、容器比内容高时富余高度被谁吃掉（`.fill` 分布的
/// stack 会挑压缩阻力最低的那个拉伸，于是那行字符数/行数被拉成一条高条、文字垂直居中）。
/// 这些都是白付的 —— 高度定了，卡片的高度自然由内部约束推出来。
final class HierarchyMultilineTextView: UIView, HierarchyValueInput {

    var onValidityChange: ((Bool) -> Void)?

    /// 没编辑过就写回原值。空串是合法值（`label.text = ""` 有意义），所以这里永远合法。
    private let originalText: String
    private var isEdited = false

    /// 输入区高度。**字面量，不随内容变**：内容多了由 `textView` 自己滚。
    private static let height: CGFloat = 280

    init(text: String) {
        self.originalText = text
        super.init(frame: .zero)
        textView.text = text
        setupSubviews()
        updateMeta()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - HierarchyValueInput

    func readValue() -> ValueKind? {
        .text(isEdited ? (textView.text ?? "") : originalText)
    }

    // MARK: - Views

    private lazy var textView: UITextView = {
        let view = UITextView()
        // 等宽：改的是别人代码里的字面量，字宽固定才看得出有没有多一个空格
        view.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        view.backgroundColor = HierarchyEditorStyle.fieldBackground
        view.layer.cornerRadius = HierarchyEditorStyle.fieldRadius
        view.layer.masksToBounds = true
        view.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        view.delegate = self
        // 内容超出固定高度时自己滚（`isScrollEnabled` 默认就是 true，写出来是把意图写明）
        view.isScrollEnabled = true

        // 六道开关全关。当年那个 alert 一个都没关：打 `hello world` 进去，
        // 写出来是 `Hello world` —— 首字母被系统大写了，而这个过程用户看不见。
        HierarchyEditorStyle.disableSmartInput(view)
        return view
    }()

    private lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private func setupSubviews() {
        let stack = UIStackView(arrangedSubviews: [textView, metaLabel])
        stack.axis = .vertical
        stack.spacing = 8

        // 只有 `textView` 的高度是定的；`metaLabel` 拿自己的固有高度。
        // 给 `metaLabel` 一个 required 的垂直 hugging，是为了让它**永远**不参与拉伸 ——
        // 免得以后有人给本视图加高时，富余高度又落到那行小字上。
        metaLabel.setContentHuggingPriority(.required, for: .vertical)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.heightAnchor.constraint(equalToConstant: Self.height),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateMeta() {
        let text = textView.text ?? ""
        let lines = text.isEmpty ? 0 : text.components(separatedBy: .newlines).count
        metaLabel.text = "\(text.count) 字符 · \(lines) 行"
    }
}

// MARK: - UITextViewDelegate

extension HierarchyMultilineTextView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        isEdited = true
        updateMeta()
    }
}
