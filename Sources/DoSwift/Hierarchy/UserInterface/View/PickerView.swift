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
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 56.0, height: 56.0)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 56.0, height: 56.0)
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
        let imageView = UIImageView(image: UIImage(systemName: "dot.scope"))
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
}
