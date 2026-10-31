//
//  DraggableLayoutView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/09/30
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    final class DraggableLayoutView: DO.DraggableView {

        let contentView: UIView

        init(contentView: UIView) {
            self.contentView = contentView
            super.init(frame: .zero)

            addSubview(contentView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return contentView.systemLayoutSizeFitting(size)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            contentView.frame = bounds
        }

    }
}
