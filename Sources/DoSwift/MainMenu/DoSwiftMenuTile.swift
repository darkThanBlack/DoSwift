//
//  DoSwiftMenuTile.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 主菜单面板里的一个方块：**图标在上、文字在下**，整体居中。
///
/// 形态照搬 DoKit 自己的主菜单（`DoraemonHomeCell` 的方块网格），而不是
/// 「图标在左、文字在右」的列表行。常用工具靠图标一眼认出，文字只是补充，
/// 所以图标占主位、文字退到下面并允许收缩。
///
/// 方块自己回答尺寸问题（`sizeThatFits`），面板只负责摆放。
final class DoSwiftMenuTile: UIControl {

    /// 点击回调。方块自己不执行任何工具逻辑。
    var onTap: ((DoSwiftMenuItem) -> Void)?

    private(set) var item: DoSwiftMenuItem?

    // MARK: - Metrics（自己的尺寸自己定，外层通过 `sizeThatFits` 取）

    private static let labelFontSize: CGFloat = 11
    private static let iconSize: CGFloat = 24
    private static let topPadding: CGFloat = 8
    private static let iconLabelGap: CGFloat = 4
    private static let bottomPadding: CGFloat = 6

    /// 高度由内容推出来，不写死：改字号或图标尺寸会自动跟着变，
    /// 也保证 `sizeThatFits` 与实际排版用的是同一组数
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
        // 个别英文标题（UserDefaults / Lumberjack）比方块窄，允许收缩而不截断
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

    /// 宽度由面板按列宽传进来（方块只在这个宽度里排版，文字窄了靠 `minimumScaleFactor` 收），
    /// 高度按「上下留白 + 图标 + 间距 + 一行文字」算出来。
    ///
    /// 不再实现 `intrinsicContentSize`：方块由面板显式摆 frame，没有任何 Auto Layout
    /// 会来问它，而它唯一的用途是让这里的 `.zero` 需要一个宽度兜底——那就是当初
    /// `tileWidth` 被复制进这个文件的原因。
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
