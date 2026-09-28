//
//  DoSwiftToolRailTile.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 度量集中定义在 `DoSwiftToolRailView.Metrics`。这里起个别名，
/// 免得每个用到的地方都写全限定名（也免得再把类型名当值赋给变量）。
typealias Metrics = DoSwiftToolRailView.Metrics

/// 工具轨里的一个方块：**图标在上、文字在下**，整体居中。
///
/// 形态照搬 DoKit 自己的主菜单（`DoraemonHomeCell` 的方块网格），而不是
/// 「图标在左、文字在右」的列表行。常用工具靠图标一眼认出，文字只是补充，
/// 所以图标占主位、文字退到下面并允许收缩。
///
/// 方块自己回答尺寸问题（`sizeThatFits`），轨道只负责摆放。
final class DoSwiftToolRailTile: UIControl {

    /// 点击回调。方块自己不执行任何工具逻辑。
    var onTap: ((DoSwiftMenuItem) -> Void)?

    private(set) var tool: DoSwiftMenuItem?

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
        label.font = .systemFont(ofSize: DoSwiftToolRailView.Metrics.tileLabelFontSize, weight: .regular)
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

    /// 宽度由轨道按列宽传进来；高度按「上下留白 + 图标 + 间距 + 一行文字」算出来。
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width > 0 ? size.width : DoSwiftToolRailView.Metrics.tileWidth
        return CGSize(width: width, height: DoSwiftToolRailView.Metrics.tileHeight)
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        highlightView.frame = bounds

        iconView.frame = CGRect(
            x: (bounds.width - Metrics.tileIconSize) / 2,
            y: Metrics.tileTopPadding,
            width: Metrics.tileIconSize,
            height: Metrics.tileIconSize
        )

        titleLabel.frame = CGRect(
            x: 2,
            y: iconView.frame.maxY + Metrics.tileIconLabelGap,
            width: max(0, bounds.width - 4),
            height: max(0, bounds.height - iconView.frame.maxY - Metrics.tileIconLabelGap - Metrics.tileBottomPadding)
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

    func configure(with tool: DoSwiftMenuItem) {
        self.tool = tool
        titleLabel.text = tool.title
        iconView.image = tool.icon
        iconView.isHidden = (tool.icon == nil)
        isEnabled = tool.isEnabled
        alpha = tool.isEnabled ? 1.0 : 0.4
    }

    @objc private func handleTap() {
        guard let tool = tool else { return }
        onTap?(tool)
    }
}
