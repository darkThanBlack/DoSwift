//
//  MenuNavigationBar.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//


import UIKit

extension DO {
    
    @objc(DOMenuNavigationBar)
    final class MenuNavigationBar: UIView {
        
        var onClose: (() -> Void)?
        
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
        
        @objc private func handleClose() {
            onClose?()
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: size.width, height: 44.0)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let inset: CGFloat = 12
            hairline.frame = CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5)
            
            let buttonSize: CGFloat = 32.0
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
        
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = "DoSwift"
            label.font = .systemFont(ofSize: 13.0, weight: .semibold)
            label.textColor = .label
            return label
        }()
        
        private lazy var closeButton: UIButton = {
            let button = UIButton(type: .system)
            let symbol = UIImage.SymbolConfiguration(
                pointSize: 13.0,
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
        
    }
    
}
