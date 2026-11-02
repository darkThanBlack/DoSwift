//
//  MenuGroupHeaderView.swift
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
    
    @objc(DOMenuGroupHeaderView)
    final class MenuGroupHeaderView: UIView {
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: size.width, height: 28.0)
        }
        
        init(title: String) {
            super.init(frame: .zero)
            backgroundColor = .clear
            
            titleLabel.text = title
            
            addSubview(hairline)
            addSubview(titleLabel)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let inset: CGFloat = 12.0
            hairline.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)
            titleLabel.frame = CGRect(
                x: inset,
                y: 0,
                width: max(0, bounds.width - inset * 2),
                height: bounds.height
            )
        }
        
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 11.0, weight: .semibold)
            label.textColor = .secondaryLabel
            return label
        }()
        
        private lazy var hairline: UIView = {
            let view = UIView()
            view.backgroundColor = .separator
            return view
        }()
        
    }
    
}
