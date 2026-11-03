//
//  FileRowView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// 一行文件 / 文件夹的内容视图，结构 `H[ iconBox | V[Title, Detail] | spacer | RightImage ]`。
    /// 是普通 `UIView` 而不是 cell；只有展示，没有选择态（进入 / 返回 / 置灰由框架判断）。
    @objc(DOFileRowView)
    final class FileRowView: UIView {

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Update

        func update(node: any DO.FileNode) {
            iconBox.backgroundColor = DO.FileBrowserStyle.iconBackgroundColor
            iconImageView.image = DO.FileBrowserStyle.nodeImage(node)
            iconImageView.tintColor = DO.FileBrowserStyle.nodeTintColor(node)

            titleLabel.text = node.nodeName
            titleLabel.isHidden = (node.nodeName?.isEmpty ?? true)

            detailLabel.text = detailText(for: node)
            detailLabel.isHidden = (detailLabel.text?.isEmpty ?? true)

            /// 只有文件夹有尾部箭头；文件行置空但保留槽位 —— 长名截断线才对得齐
            arrowImageView.image = (node.nodeKind == .folder) ? DO.FileBrowserStyle.arrowImage() : nil
        }

        /// 副标题：文件给大小；文件夹不给（保持列表干净）
        private func detailText(for node: any DO.FileNode) -> String? {
            guard node.nodeKind == .file, let size = node.nodeSize, size > 0 else { return nil }
            return DO.FileBrowserStyle.formatSize(size)
        }

        // MARK: - View

        /// 行内左右留白（与尾部箭头、左侧图标盒共用）
        private let insetX: CGFloat = 16.0

        /// 上下留白：行高 = max(图标盒, 文字块) + 上下留白，随内容撑开（不设固定行高）
        private let insetY: CGFloat = 16.0

        private func loadViews(in box: UIView) {
            leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            /// 剩余空间一律给 spacer：文字块留在自己的自然宽度上（否则它会和 spacer 同优先级抢空间）
            leftStack.setContentHuggingPriority(UILayoutPriority(251.0), for: .horizontal)
            arrowImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

            box.addSubview(stacks)
            stacks.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: insetY),
                stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: insetX),
                stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -insetX),
                stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -insetY),
                /// 高度下限 = 两行（标题 + 副标题）：文件夹没有副标题，靠它跟文件行一样高
                stacks.heightAnchor.constraint(greaterThanOrEqualToConstant: 36.0),
            ])

            iconBox.addSubview(iconImageView)
            iconImageView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                iconBox.widthAnchor.constraint(equalToConstant: 32.0),
                iconBox.heightAnchor.constraint(equalToConstant: 32.0),

                iconImageView.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 17.0),
                iconImageView.heightAnchor.constraint(equalToConstant: 17.0),

                arrowImageView.widthAnchor.constraint(equalToConstant: 12.0),
                arrowImageView.heightAnchor.constraint(equalToConstant: 12.0),
            ])

            /// 左列文字整宽（让 textAlignment 说了算）
            for view in leftStack.arrangedSubviews {
                view.widthAnchor.constraint(equalTo: leftStack.widthAnchor).isActive = true
            }
        }

        // MARK: - Subviews

        private lazy var stacks: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [
                iconBox,
                leftStack,
                spacer,
                arrowImageView
            ])
            stacks.axis = .horizontal
            stacks.alignment = .center
            stacks.distribution = .fill
            stacks.spacing = 12.0
            return stacks
        }()

        private lazy var leftStack: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [
                titleLabel, detailLabel
            ])
            stacks.axis = .vertical
            stacks.alignment = .center
            stacks.distribution = .fill
            stacks.spacing = 4.0
            return stacks
        }()

        /// 把文字块和尾部箭头之间的空间撑开
        private lazy var spacer: UIView = {
            let view = UIView()
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return view
        }()

        /// 图标底色盒子
        private lazy var iconBox: UIView = {
            let view = UIView()
            view.layer.cornerRadius = 8.0
            view.layer.masksToBounds = true
            return view
        }()

        private lazy var iconImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            return view
        }()

        private lazy var titleLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 1
            /// 文件名场景：中间截断比尾部截断更好认
            view.lineBreakMode = .byTruncatingMiddle
            view.font = DO.FileBrowserStyle.titleFont
            view.textColor = DO.FileBrowserStyle.textColor
            return view
        }()

        private lazy var detailLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 1
            view.lineBreakMode = .byTruncatingMiddle
            view.font = DO.FileBrowserStyle.detailFont
            view.textColor = DO.FileBrowserStyle.lightTextColor
            return view
        }()

        private lazy var arrowImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.tintColor = DO.FileBrowserStyle.disabledTextColor
            return view
        }()
    }
}
