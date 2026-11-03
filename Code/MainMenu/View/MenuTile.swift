//
//  MenuTile.swift
//  DoSwift
//
//  Created by moonShadow on 2026/09/28
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {
    
    @objc(DOMenuTile)
    final class MenuTile: UIControl {

        var onTap: ((DO.MenuItem) -> Void)?

        private(set) var item: DO.MenuItem?

        private static let labelFontSize: CGFloat = 11
        private static let iconSize: CGFloat = 24
        private static let topPadding: CGFloat = 8
        private static let iconLabelGap: CGFloat = 4
        private static let bottomPadding: CGFloat = 6

        private static let height: CGFloat = ceil(
            topPadding
                + iconSize
                + iconLabelGap
                + UIFont.systemFont(ofSize: labelFontSize, weight: .regular).lineHeight
                + bottomPadding
        )

        private let highlightView: UIView = {
            let view = UIView()
            view.backgroundColor = .tertiarySystemFill
            view.layer.cornerRadius = 10
            view.alpha = 0
            view.isUserInteractionEnabled = false
            return view
        }()

        private let iconView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.tintColor = .secondaryLabel
            return view
        }()

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: DO.MenuTile.labelFontSize, weight: .regular)
            label.textColor = .label
            label.textAlignment = .center
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }

        private func setup() {
            addSubview(highlightView)
            addSubview(iconView)
            addSubview(titleLabel)
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: size.width, height: DO.MenuTile.height)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            highlightView.frame = bounds

            let iconSize = DO.MenuTile.iconSize
            iconView.frame = CGRect(
                x: (bounds.width - iconSize) / 2,
                y: DO.MenuTile.topPadding,
                width: iconSize,
                height: iconSize
            )

            titleLabel.frame = CGRect(
                x: 2,
                y: iconView.frame.maxY + DO.MenuTile.iconLabelGap,
                width: max(0, bounds.width - 4),
                height: max(0, bounds.height - iconView.frame.maxY - DO.MenuTile.iconLabelGap - DO.MenuTile.bottomPadding)
            )
        }

        override var isHighlighted: Bool {
            didSet {
                UIView.animate(withDuration: 0.12) {
                    self.highlightView.alpha = self.isHighlighted ? 1 : 0
                }
            }
        }

        func configure(with item: DO.MenuItem) {
            self.item = item
            titleLabel.text = item.title
            iconView.image = item.icon
            iconView.isHidden = (item.icon == nil)
        }

        @objc private func handleTap() {
            guard let item = item else { return }
            onTap?(item)
        }
    }
}
