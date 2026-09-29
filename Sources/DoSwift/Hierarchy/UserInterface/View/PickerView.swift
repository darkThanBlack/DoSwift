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
        pickerViewInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        pickerViewInit()
    }

    private func pickerViewInit() {
        // 拾取器要能贴到屏幕边缘工作，越界只在松手时收回
        releasePolicy = .bounceBack
        backgroundColor = .clear
        layer.cornerRadius = min(bounds.width, bounds.height) / 2

        // TODO: Use actual asset - doraemon_visual
        let imageView = UIImageView(image: UIImage(systemName: "scope"))
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
}
