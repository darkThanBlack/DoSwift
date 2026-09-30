//
//  HierarchyInfoView.swift
//  DoSwift
//
//  Translated from DKHierarchyInfoView.m / DKHierarchyInfoView.h
//

import UIKit

// MARK: - Delegate

protocol HierarchyInfoViewDelegate: AnyObject {
    func hierarchyInfoView(_ view: HierarchyInfoView, didSelect action: HierarchyInfoViewAction)
    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView)
}

/// 浮窗上的三个动作。不再需要 `Int` rawValue——按钮自己持有动作（见 `ActionButton`），
/// 不必再用 `UIButton.tag` 做映射。
enum HierarchyInfoViewAction {
    case showParent
    case showSubview
    case showMoreInfo
}

/// 选中视图的属性浮窗——**纯内容视图**。
///
/// 内部全部是 Auto Layout + UIStackView：行随内容增减，高度由约束算出来。
/// 它不认识拖拽、也不管自己在屏幕上的位置和大小——那些由宿主容器
/// `DraggableLayoutView` 负责。
final class HierarchyInfoView: UIView {

    // MARK: - Metrics

    private enum Metrics {
        static let inset: CGFloat = 12
        static let rowSpacing: CGFloat = 6
        static let sectionSpacing: CGFloat = 10
        static let closeButtonSize: CGFloat = 28
        static let actionButtonHeight: CGFloat = 34
        static let cornerRadius: CGFloat = 10
    }

    // MARK: - Public

    weak var delegate: HierarchyInfoViewDelegate?

    private(set) var selectedView: UIView?

    private(set) lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let frameRow = InfoRowView(key: "Frame:")
    private let backgroundColorRow = InfoRowView(key: "Background:")
    private let textColorRow = InfoRowView(key: "Text Color:")
    private let fontRow = InfoRowView(key: "Font:")
    private let tagRow = InfoRowView(key: "Tag:")

    private let actionButtonsStack = UIStackView()

    private lazy var parentButton = makeActionButton(.showParent, "Parent Views", "arrow.up")
    private lazy var subviewsButton = makeActionButton(.showSubview, "Subviews", "arrow.down")
    private lazy var moreButton = makeActionButton(.showMoreInfo, "More Info", "info.circle")

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        hierarchyInfoViewInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hierarchyInfoViewInit()
    }

    private func hierarchyInfoViewInit() {
        backgroundColor = .systemBackground
        layer.cornerRadius = Metrics.cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor

        // 头部：类名 + 关闭
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Metrics.closeButtonSize),
        ])
        let header = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        // 信息行。值为 nil 的行自己把自己隐藏掉，stack 会自动重排——
        // 这正是换成 stack 之后不再需要手工算高度的原因。
        let infoStack = UIStackView(arrangedSubviews: [
            frameRow, backgroundColorRow, textColorRow, fontRow, tagRow,
        ])
        infoStack.axis = .vertical
        infoStack.spacing = Metrics.rowSpacing

        // 动作按钮：一行三个等宽
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.distribution = .fillEqually
        actionButtonsStack.spacing = 8
        actionButtonsStack.heightAnchor.constraint(equalToConstant: Metrics.actionButtonHeight).isActive = true
        [parentButton, subviewsButton, moreButton].forEach(actionButtonsStack.addArrangedSubview)

        let root = UIStackView(arrangedSubviews: [header, infoStack, actionButtonsStack])
        root.axis = .vertical
        root.spacing = Metrics.sectionSpacing
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.inset),
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.inset),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.inset),
            root.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.inset),
        ])
    }

    // MARK: - Update

    func updateSelectedView(_ view: UIView?) {
        guard let view = view, view !== selectedView else { return }
        selectedView = view

        titleLabel.text = String(describing: type(of: view))
        frameRow.value = HierarchyFormatterTool.string(from: view.frame)
        backgroundColorRow.value = view.backgroundColor?.hierarchy_description
        tagRow.value = view.tag == 0 ? nil : "\(view.tag)"

        if let label = view as? UILabel {
            textColorRow.value = label.textColor.hierarchy_description
            fontRow.value = String(format: "%0.2f", label.font.pointSize)
        } else {
            textColorRow.value = nil
            fontRow.value = nil
        }

        parentButton.isEnabled = view.superview != nil
        subviewsButton.isEnabled = !view.subviews.isEmpty
        moreButton.isEnabled = true
    }

    // MARK: - Actions

    @objc private func actionTapped(_ sender: ActionButton) {
        delegate?.hierarchyInfoView(self, didSelect: sender.action)
    }

    @objc private func closeTapped() {
        delegate?.hierarchyInfoViewDidSelectClose(self)
    }

    // MARK: - Helpers

    private func makeActionButton(_ action: HierarchyInfoViewAction, _ title: String, _ symbol: String) -> UIButton {
        let button = ActionButton(action)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.tertiaryLabel, for: .disabled)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }

    /// 自己持有动作的按钮，省掉 `UIButton.tag` 那层 Int↔枚举 的来回转换。
    private final class ActionButton: UIButton {

        let action: HierarchyInfoViewAction

        init(_ action: HierarchyInfoViewAction) {
            self.action = action
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Info Row

/// 一行「键：值」。值为 nil 时整行隐藏。
///
/// 隐藏靠 `isHidden`——UIStackView 会把隐藏的 arranged subview 从布局里摘掉，
/// 所以不需要任何手工高度计算。
private final class InfoRowView: UIStackView {

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    init(key: String) {
        super.init(frame: .zero)

        axis = .horizontal
        alignment = .firstBaseline
        spacing = 4

        let keyLabel = UILabel()
        keyLabel.text = key
        keyLabel.font = .boldSystemFont(ofSize: 13)
        keyLabel.textColor = .label
        // 键不该被压缩，值才是需要换行的那个
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)
        keyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addArrangedSubview(keyLabel)
        addArrangedSubview(valueLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var value: String? {
        get { valueLabel.text }
        set {
            valueLabel.text = newValue
            isHidden = (newValue == nil)
        }
    }
}
