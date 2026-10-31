//
//  PickerView.swift
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

    protocol PickerViewDelegate: AnyObject {
        func pickerDidBeginDrag(_ picker: DO.PickerView)
        func pickerDidMove(_ picker: DO.PickerView)
        func pickerDidEndDrag(_ picker: DO.PickerView)
    }

    class PickerView: DO.DraggableView {

        weak var delegate: DO.PickerViewDelegate?

        override init(frame: CGRect) {
            super.init(frame: frame)
            initUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            initUI()
        }

        private func initUI() {
            backgroundColor = .clear
            addSubview(icon)
        }

        override func dragDidBegin() {
            delegate?.pickerDidBeginDrag(self)
        }

        override func dragDidUpdate(offset: CGPoint) {
            delegate?.pickerDidMove(self)
        }

        override func dragDidEnd() {
            delegate?.pickerDidEndDrag(self)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: 60.0, height: 60.0)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let iconSize: CGFloat = 44.0
            icon.frame = CGRect(
                x: (bounds.width - iconSize) / 2,
                y: (bounds.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
        }

        private lazy var icon: UIImageView = {
            let imageView = UIImageView(image: UIImage(systemName: "scope"))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .systemIndigo
            return imageView
        }()

    }
}
