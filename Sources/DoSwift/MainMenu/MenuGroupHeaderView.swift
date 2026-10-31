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

    final class MenuGroupHeaderView: UIView {

        private static let headerHeight: CGFloat = 28

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: size.width, height: DO.MenuGroupHeaderView.headerHeight)
        }

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .secondaryLabel
            return label
        }()

        private let hairline: UIView = {
            let view = UIView()
            view.backgroundColor = .separator
            return view
        }()

        init(title: String, showsTopHairline: Bool) {
            super.init(frame: .zero)
            backgroundColor = .clear
            titleLabel.text = title
            hairline.isHidden = !showsTopHairline
            addSubview(hairline)
            addSubview(titleLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let inset: CGFloat = 12
            hairline.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)
            titleLabel.frame = CGRect(
                x: inset,
                y: 0,
                width: max(0, bounds.width - inset * 2),
                height: bounds.height
            )
        }
    }
}
