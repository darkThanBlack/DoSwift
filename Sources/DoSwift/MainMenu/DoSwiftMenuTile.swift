//
//  DoSwiftMenuTile.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

final class DoSwiftMenuTile: UIControl {

    var onTap: ((DoSwiftMenuItem) -> Void)?

    private(set) var item: DoSwiftMenuItem?

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

    // MARK: - Subviews

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
        label.font = .systemFont(ofSize: DoSwiftMenuTile.labelFontSize, weight: .regular)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    // MARK: - Initializers

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

    // MARK: - Size

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: DoSwiftMenuTile.height)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        highlightView.frame = bounds

        let iconSize = DoSwiftMenuTile.iconSize
        iconView.frame = CGRect(
            x: (bounds.width - iconSize) / 2,
            y: DoSwiftMenuTile.topPadding,
            width: iconSize,
            height: iconSize
        )

        titleLabel.frame = CGRect(
            x: 2,
            y: iconView.frame.maxY + DoSwiftMenuTile.iconLabelGap,
            width: max(0, bounds.width - 4),
            height: max(0, bounds.height - iconView.frame.maxY - DoSwiftMenuTile.iconLabelGap - DoSwiftMenuTile.bottomPadding)
        )
    }

    // MARK: - Highlight

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.highlightView.alpha = self.isHighlighted ? 1 : 0
            }
        }
    }

    // MARK: - Configuration

    func configure(with item: DoSwiftMenuItem) {
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
