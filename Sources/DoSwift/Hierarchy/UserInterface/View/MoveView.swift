//
//  MoveView.swift
//  DoSwift
//
//  Translated from DKMoveView.m / DKMoveView.h
//

import UIKit

/// 可拖动视图基类
class MoveView: UIView {

    // MARK: - Properties

    /// 拖拽手势
    private(set) lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        return gesture
    }()

    /// 是否允许越界
    var isOverflow: Bool = false

    /// 是否已移动过
    private(set) var isMoved: Bool = false

    /// 是否可移动
    var isMovable: Bool {
        get { panGesture.isEnabled }
        set { panGesture.isEnabled = newValue }
    }

    /// 可移动区域（以父视图为坐标系），CGRectNull 表示无限制
    var movableRect: CGRect = .null

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        moveViewInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        moveViewInit()
    }

    private func moveViewInit() {
        addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture

    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        guard gesture === panGesture else { return }

        if !isMoved { isMoved = true }

        let offset = panGesture.translation(in: self)
        viewWillUpdateOffset(panGesture, offset: offset)
        panGesture.setTranslation(.zero, in: self)
        changeFrame(with: offset)
        viewDidUpdateOffset(panGesture, offset: offset)
    }

    // MARK: - Frame Calculation

    private func changeFrame(with point: CGPoint) {
        var center = self.center
        center.x += point.x
        center.y += point.y

        if isOverflow {
            center.x = max(min(center.x, superview?.bounds.width ?? 0), 0)
            center.y = max(min(center.y, superview?.bounds.height ?? 0), 0)
        } else {
            let halfW = frame.width / 2
            let halfH = frame.height / 2
            if center.x < halfW { center.x = halfW }
            else if center.x > (superview?.bounds.width ?? 0) - halfW { center.x = (superview?.bounds.width ?? 0) - halfW }
            if center.y < halfH { center.y = halfH }
            else if center.y > (superview?.bounds.height ?? 0) - halfH { center.y = (superview?.bounds.height ?? 0) - halfH }
        }

        if !movableRect.isNull {
            if !movableRect.contains(center) {
                center.x = max(movableRect.minX, min(center.x, movableRect.maxX))
                center.y = max(movableRect.minY, min(center.y, movableRect.maxY))
            }
        }

        self.center = center
    }

    /// 子类重写以响应拖动开始/进行中
    func viewWillUpdateOffset(_ sender: UIPanGestureRecognizer, offset: CGPoint) {}
    func viewDidUpdateOffset(_ sender: UIPanGestureRecognizer, offset: CGPoint) {}
}
