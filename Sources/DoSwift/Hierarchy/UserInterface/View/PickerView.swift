//
//  PickerView.swift
//  DoSwift
//
//  Translated from DKPickerView.m / DKPickerView.h
//

import UIKit

/// 圆形拾取器基类
class PickerView: DraggableView {
    
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
    
    /// 尺寸只由这里回答，调用方读它再摆位置
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
