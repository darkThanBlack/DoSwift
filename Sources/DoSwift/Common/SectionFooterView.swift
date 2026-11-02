//
//  SectionFooterView.swift
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

    @objc(DOSectionFooterView)
    final class SectionFooterView: UITableViewHeaderFooterView {

        let titleLabel: UILabel = {
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            return label
        }()

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            loadViews()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            loadViews()
        }

        private func loadViews() {
            contentView.addSubview(titleLabel)

            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            ])
        }
    }
}
