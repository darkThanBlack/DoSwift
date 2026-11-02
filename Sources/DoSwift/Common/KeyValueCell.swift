//
//  KeyValueCell.swift
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

    protocol KeyValueCellDataSource {

        var title: String? { get }

        var detail: String? { get }

        var rightImage: UIImage? { get }
    }

    @objc(DOKeyValueCell)
    final class KeyValueCell: UITableViewCell, DO.SectionCell {

        weak var sectionDelegate: DO.SectionCellDelegate?

        var detailNumberOfLines: Int = 0 {
            didSet { detailLabel.numberOfLines = detailNumberOfLines }
        }

        func update(_ dataSource: DO.KeyValueCellDataSource?) {
            update(
                title: dataSource?.title,
                detail: dataSource?.detail,
                rightImage: dataSource?.rightImage
            )
        }

        func update(title: String? = nil, detail: String? = nil, rightImage: UIImage? = nil) {
            titleLabel.text = title
            detailLabel.text = detail

            rightImageView.image = rightImage
            rightImageView.isHidden = (rightImage == nil)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            selectionStyle = .none
            loadViews(in: contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            guard selected else { return }
            sectionDelegate?.sectionCellDidTrigger(self)
        }

        private func loadViews(in box: UIView) {
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
            rightImageView.setContentHuggingPriority(.required, for: .horizontal)
            rightImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

            stacks.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(stacks)

            NSLayoutConstraint.activate([
                stacks.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
                stacks.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
                stacks.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
                stacks.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
            ])
        }

        private lazy var stacks: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [textStack, rightImageView])
            stacks.axis = .horizontal
            stacks.alignment = .center
            stacks.spacing = 8
            return stacks
        }()

        private lazy var textStack: UIStackView = {
            let stacks = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
            stacks.axis = .vertical
            stacks.alignment = .leading
            stacks.spacing = 2.0
            return stacks
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .label
            label.numberOfLines = 0
            return label
        }()

        private lazy var detailLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            return label
        }()

        private lazy var rightImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .tertiaryLabel
            imageView.isHidden = true
            return imageView
        }()
    }
}
