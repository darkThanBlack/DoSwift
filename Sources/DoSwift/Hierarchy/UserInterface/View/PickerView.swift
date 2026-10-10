//
//  PickerView.swift
//  DoSwift
//
//  Translated from DKPickerView.m / DKPickerView.h
//

import UIKit

/// 拾取器的拖动事件出口。
///
/// 三个事件只报「发生了什么」，不报「拾取到了什么」：`selectedView()` 由子类按自己的
/// 搜索策略算，而且 `settle()` 归位后位置还会再变一次，所以接收方一律**按需自己拉**，
/// 不指望事件带 payload。位置只有一个出处——`picker.center`，因此这里也不转发 `offset`。
protocol PickerViewDelegate: AnyObject {
    func pickerDidBeginDrag(_ picker: PickerView)
    func pickerDidMove(_ picker: PickerView)
    func pickerDidEndDrag(_ picker: PickerView)
}

/// 圆形拾取器基类。
///
/// 定位、拖动、归位全部交给 `DraggableView`；本类只回答两件事：**自己多大**、
/// **拖动时把事件转出去**。
class PickerView: DraggableView {

    /// 拖动事件出口
    weak var delegate: PickerViewDelegate?
    
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

    // MARK: - DraggableView 钩子

    /// pan 手势真正成立时才会走到——轻点不会，所以可以直接当作「开始拖动」用。
    override func dragDidBegin() {
        delegate?.pickerDidBeginDrag(self)
    }

    override func dragDidUpdate(offset: CGPoint) {
        delegate?.pickerDidMove(self)
    }

    /// 注意语义是「位置已定」而不是「手势结束」：`settle()` 的三个出口都会走到这里，
    /// 首次布局、旋转归位同样触发。
    override func dragDidEnd() {
        delegate?.pickerDidEndDrag(self)
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
