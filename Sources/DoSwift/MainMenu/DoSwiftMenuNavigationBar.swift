//
//  DoSwiftMenuNavigationBar.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/9
//  
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//
    

import UIKit

/// 主菜单面板顶部的固定栏：标题 + 关闭按钮。
///
/// 关闭按钮存在的意义是给面板一个**明确的出口**。面板是非模态的、没有遮罩，
/// 所以没有「点外部关闭」；之前唯一的出口是再点一次手柄，不够显而易见。
final class DoSwiftMenuNavigationBar: UIView {

    /// 关闭按钮回调
    var onClose: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "DoSwift"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        // 不指定配置的话，符号会按按钮默认字号（约 17pt）渲染，在这个窄面板里太重
        let symbol = UIImage.SymbolConfiguration(
            pointSize: DoSwiftMenuMetrics.closeButtonSymbolSize,
            weight: .medium
        )
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbol), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()

    private let hairline: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(hairline)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DoSwiftMenuMetrics.horizontalPadding
        hairline.frame = CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5)

        let buttonSize = DoSwiftMenuMetrics.closeButtonSize
        closeButton.frame = CGRect(
            x: bounds.width - inset - buttonSize,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )

        titleLabel.frame = CGRect(
            x: inset,
            y: 0,
            width: max(0, closeButton.frame.minX - inset * 2),
            height: bounds.height
        )
    }

    @objc private func handleClose() {
        onClose?()
    }
}
