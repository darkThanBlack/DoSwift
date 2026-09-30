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
    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView)
}

/// 选中视图的属性浮窗
final class HierarchyInfoView: UIView {
    
    weak var delegate: HierarchyInfoViewDelegate?
    
    private(set) weak var selectedView: UIView?
    
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
        
        [rootStack, closeButton, actionStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
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
        let stack = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
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
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
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

/// 单行
private final class HierarchyInfoRowView: UIView {
    
    var value: String? {
        get { valueLabel.text }
        set {
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
