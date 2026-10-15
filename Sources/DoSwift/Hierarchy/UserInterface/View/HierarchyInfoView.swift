//
//  HierarchyInfoView.swift
//  DoSwift
//
//  Translated from DKHierarchyInfoView.m / DKHierarchyInfoView.h
//

import UIKit

// MARK: - Delegate

protocol HierarchyInfoViewDelegate: AnyObject {
    func hierarchyInfoViewDidSelectParent(_ view: HierarchyInfoView)
    func hierarchyInfoViewDidSelectSubview(_ view: HierarchyInfoView)
    func hierarchyInfoViewDidSelectMoreInfo(_ view: HierarchyInfoView)
    func hierarchyInfoViewDidSelectSetting(_ view: HierarchyInfoView)
    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView)
}

/// 选中视图的属性浮窗
final class HierarchyInfoView: UIView {
    
    weak var delegate: HierarchyInfoViewDelegate?
    
    private(set) weak var selectedView: UIView?
    
    /// 更新标尺行。
    ///
    /// 与 `updateSelectedView` 分开是必须的：后者在选中项未变时直接 return，
    /// 而手柄每动一步，四个距离都在变。
    func updateRulerInfo(_ text: String?) {
        rulerRow.value = text
    }
    
    /// 更新取色行（屏幕上的实际像素）。
    ///
    /// 与 `updateSelectedView` 分开是必须的：它说的是「手柄指着的那一点渲染出来是什么色」，
    /// 而不是「这个 view 的属性写了什么色」——那两个值可以不一样（叠加、毛玻璃、渐变）。
    func updatePixelColor(_ description: String?) {
        pixelColorRow.value = description
    }
    
    func updateSelectedView(_ view: UIView?) {
        guard let view = view, view !== selectedView else { return }
        selectedView = view

        // 行名与值一律问引擎（JSON 是唯一数据源），面板这边只决定「要哪几行、摆在哪儿」。
        // 这里不再自己读 `view.backgroundColor` / `label.font.pointSize`——那样值的格式
        // 就有两套权威，迟早和详情页说的不一样。
        apply("class", of: view, to: nameRow)
        apply("frame", of: view, to: frameRow)
        apply("backgroundColor", of: view, to: backgroundColorRow)
        apply("textColor", of: view, to: textColorRow)
        apply("font", of: view, to: fontRow)
        apply("tag", of: view, to: tagRow)

        parentButton.isEnabled = view.superview != nil
        subviewsButton.isEnabled = !view.subviews.isEmpty
        moreButton.isEnabled = true
    }

    /// 取一行填进来。
    ///
    /// 属性**是否适用**不用在这里判断：`textColor` 在 UIView 的类链上找不到，引擎返回 nil，
    /// 行自然收起——原来那段 `if let label = view as? UILabel` 因此可以删掉。
    private func apply(_ key: String, of view: UIView, to row: HierarchyInfoRowView) {
        let model = HierarchyPropertyEngine.shared.cellModel(for: view, key: key)
        row.key = model?.title
        row.value = model?.detailTitle
    }
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews(in: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews(in box: UIView) {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12.0
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.separator.cgColor
        
        addSubview(rootStack)
        
        [rootStack, closeButton, settingButton, actionStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
            settingButton.widthAnchor.constraint(equalToConstant: 28),
            settingButton.heightAnchor.constraint(equalToConstant: 28),
            
            actionStack.heightAnchor.constraint(equalToConstant: 34),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func parentTapped() {
        delegate?.hierarchyInfoViewDidSelectParent(self)
    }
    
    @objc private func subviewTapped() {
        delegate?.hierarchyInfoViewDidSelectSubview(self)
    }
    
    @objc private func moreInfoTapped() {
        delegate?.hierarchyInfoViewDidSelectMoreInfo(self)
    }
    
    @objc private func settingTapped() {
        delegate?.hierarchyInfoViewDidSelectSetting(self)
    }
    
    @objc private func closeTapped() {
        delegate?.hierarchyInfoViewDidSelectClose(self)
    }
    
    // MARK: - Views
    
    private lazy var rootStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerStack, infoStack, actionStack])
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, settingButton, closeButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            rulerRow, pixelColorRow, nameRow,
            frameRow, backgroundColorRow, textColorRow, fontRow, tagRow,
        ])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()
    
    private lazy var actionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [parentButton, subviewsButton, moreButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UI Hierarchy"
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    /// 配置入口。放标题栏而不是按钮行：按钮行有 3 个等宽按钮，再挤一个进去
    /// 每个只剩 45pt，"Parents" 这种文字会被截断。
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .system)
        // gear 属 2019 年度符号集（iOS 13）。gearshape 是 2020 年度（iOS 14），不能用。
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(settingTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var rulerRow = HierarchyInfoRowView(key: "Position:")
    private lazy var nameRow = HierarchyInfoRowView(key: "Name:")
    private lazy var pixelColorRow = HierarchyInfoRowView(key: "Pixel:")
    private lazy var frameRow = HierarchyInfoRowView(key: "Frame:")
    private lazy var backgroundColorRow = HierarchyInfoRowView(key: "Background:")
    private lazy var textColorRow = HierarchyInfoRowView(key: "Text Color:")
    private lazy var fontRow = HierarchyInfoRowView(key: "Font:")
    private lazy var tagRow = HierarchyInfoRowView(key: "Tag:")
    
    private lazy var parentButton = makeActionButton(
        title: "Parents", symbol: "arrow.up", action: #selector(parentTapped)
    )
    private lazy var subviewsButton = makeActionButton(
        title: "Childs", symbol: "arrow.down", action: #selector(subviewTapped)
    )
    private lazy var moreButton = makeActionButton(
        title: "More", symbol: "info.circle", action: #selector(moreInfoTapped)
    )
    
    // MARK: - Helpers
    
    private func makeActionButton(title: String, symbol: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.tertiaryLabel, for: .disabled)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addTarget(self, action: action, for: .touchUpInside)
        button.isEnabled = false
        return button
    }
}

// MARK: -

/// 单行。值不为空时可以点一下复制走。
private final class HierarchyInfoRowView: UIView {
    
    /// 行名。来自数据源（JSON 的 `title`），所以可写——那边改名这里自然跟着变。
    var key: String? {
        get { keyLabel.text }
        set { keyLabel.text = newValue }
    }
    
    var value: String? {
        get { valueLabel.text }
        set {
            // 标尺行每个布局周期都会被写一次，值没变就别动 —— 否则每次都会
            // 标脏父链条，把 viewDidLayoutSubviews 拖成循环
            guard valueLabel.text != newValue else { return }
            valueLabel.text = newValue
            isHidden = (newValue == nil)
        }
    }
    
    init(key: String) {
        super.init(frame: .zero)
        
        keyLabel.text = key
        
        setupSubviews(in: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews(in box: UIView) {
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)
        keyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // 点击反馈用的底色要跟面板的圆角呼应
        layer.cornerRadius = 4.0
        
        addGestureRecognizer(tapGesture)
        addSubview(stacks)
        
        [stacks].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
        })
        NSLayoutConstraint.activate([
            stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 0.0),
            stacks.leftAnchor.constraint(equalTo: box.leftAnchor, constant: 0.0),
            stacks.rightAnchor.constraint(equalTo: box.rightAnchor, constant: 0.0),
            stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: 0.0),
        ])
    }
    
    private lazy var stacks: UIStackView = {
        let stacks = UIStackView(arrangedSubviews: [keyLabel, valueLabel, UIView()])
        stacks.axis = .horizontal
        stacks.alignment = .center
        stacks.distribution = .fill
        stacks.spacing = 4.0
        return stacks
    }()
    
    // MARK: - Actions
    
    /// 点一下把这一行的值复制走。
    ///
    /// 面板里都是「看见了就要用」的短值——类名、hex、坐标、tag。此前只能照着抄一遍，
    /// 而在浮层上长按选中这条路本身也不好走。反馈就地做：闪一下底色，
    /// 免得为一个「复制成功」再去引一套 toast。
    @objc private func handleTap() {
        guard let text = valueLabel.text, !text.isEmpty else { return }
        
        UIPasteboard.general.string = text
        
        backgroundColor = .clear
        UIView.animate(withDuration: 0.12) {
            self.backgroundColor = .tertiarySystemFill
        } completion: { _ in
            UIView.animate(withDuration: 0.22) {
                self.backgroundColor = .clear
            }
        }
    }
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    
    private lazy var keyLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .label
        return label
    }()
    
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
}
