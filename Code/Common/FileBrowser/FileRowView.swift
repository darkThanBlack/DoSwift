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

    /// One row: `H[ iconBox | V[Title, Detail] | spacer | RightImage ]`.
    /// A plain `UIView` with no selection state — navigation and dimming stay outside.
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

            /// Only folders show the chevron; files keep the slot so truncation lines up.
            arrowImageView.image = (node.nodeKind == .folder) ? DO.FileBrowserStyle.arrowImage() : nil
        }

        /// Subtitle: size for files, nothing for folders.
        private func detailText(for node: any DO.FileNode) -> String? {
            guard node.nodeKind == .file, let size = node.nodeSize, size > 0 else { return nil }
            return DO.FileBrowserStyle.formatSize(size)
        }

        // MARK: - View

        /// Horizontal inset, shared with the chevron and icon box.
        private let insetX: CGFloat = 16.0

        /// Row height = max(icon box, text) + insets; no fixed height.
        private let insetY: CGFloat = 16.0

        private func loadViews(in box: UIView) {
            leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            /// Spare width goes to the spacer so the text keeps its natural width.
            leftStack.setContentHuggingPriority(UILayoutPriority(251.0), for: .horizontal)
            arrowImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

            box.addSubview(stacks)
            stacks.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: insetY),
                stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: insetX),
                stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -insetX),
                stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -insetY),
                /// Floor of two lines keeps folder rows as tall as file rows.
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

            /// Full width for the text column, so alignment decides.
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

        /// Pushes the chevron to the trailing edge.
        private lazy var spacer: UIView = {
            let view = UIView()
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return view
        }()

        /// Icon background box.
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
            /// Middle truncation reads better for file names.
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
