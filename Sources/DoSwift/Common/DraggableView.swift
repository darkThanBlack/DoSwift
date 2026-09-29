//
//  DraggableView.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/29.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 业务无关的可拖拽视图基类。
///
/// 只做两件事：**处理拖动**、**决定松手后停在哪**。不碰任何视觉。
///
/// **边界规则**
/// - 拖动过程中**不做任何夹取**，允许拖出父视图
/// - 边界一律取 `superview.bounds`，**不考虑安全区**——安全区由外层容器负责：
///   外层若在乎，就把本视图放进一个按安全区布局的容器里即可
///
/// **尺寸**由子类负责。松手后要算落点，基类必须能确定自身大小，因此子类必须
/// 通过约束 / `sizeThatFits` / 直接设 frame 给出真实尺寸。
///
/// **定位方式**：基类靠直接写 `frame.origin` 来移动自己，所以子类**不能**用约束
/// 决定自身在 superview 中的位置（centerX / top / leading 之类）——那样写进去的
/// origin 会在下一次布局被引擎覆盖，表现为「拖动时看着正常、一有 layout pass 就弹回去」。
/// 子类**内部**的排版、以及自身的尺寸，用 frame 还是约束都无所谓。
///
/// **淡化、位置记忆、外观**一律由子类通过重写 `dragDidBegin` / `dragDidUpdate` /
/// `dragDidEnd` 挂上去。基类不含任何视觉效果。需要复用某个封装好的子类时，
/// 继续往下继承，而不是往这里加开关。
open class DraggableView: UIView {

    /// 松手后的表现
    public enum ReleasePolicy {
        /// 完全不动——停在松手的位置，允许越界
        case stay
        /// 仅当越界时回弹到边界内，允许停在页面中间
        case bounceBack
        /// 吸附到最近的边界
        case absorbEdge
    }

    // MARK: - Configuration

    /// 松手后的表现。由子类在初始化时指定。
    open var releasePolicy: ReleasePolicy = .bounceBack

    /// 是否可拖动
    open var isDraggable: Bool {
        get { panGesture.isEnabled }
        set { panGesture.isEnabled = newValue }
    }

    // MARK: - State

    /// 是否正在被拖动
    public private(set) var isDragging: Bool = false

    /// 用户是否已经手动拖动过。子类可用它判断「是否该继续自动摆位」。
    public private(set) var hasDragged: Bool = false

    /// 拖动开始时的 frame.origin。用绝对式换算位置，避免增量累加在夹取处产生粘滞。
    private var frameOriginAtDragBegin: CGPoint = .zero

    // MARK: - Gesture

    /// 对外可见，便于子类与自己的手势做互斥（如 `tapGesture.require(toFail: panGesture)`）
    public private(set) lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        return gesture
    }()

    // MARK: - Initializers

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(panGesture)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizer(panGesture)
    }

    // MARK: - 子类重写

    /// 拖动开始
    open func dragDidBegin() {}

    /// 拖动进行中
    open func dragDidUpdate(offset: CGPoint) {}

    /// 位置已定。拖动结束（含被系统取消）之后会走这里，**显式调用 `settle()` 也会**
    /// ——首次布局、旋转归位时同样需要重算位置，位置记忆接在这里正好。
    open func dragDidEnd() {}

    // MARK: - Public Methods

    /// 立即按当前 `releasePolicy` 归位。用于首次布局、旋转等时机。
    open func settle(animated: Bool = true) {
        guard let barrier = superview?.bounds else { return }

        var target = frame
        switch releasePolicy {
        case .stay:
            return
        case .bounceBack:
            target.origin.x = min(max(target.origin.x, barrier.minX), barrier.maxX - target.width)
            target.origin.y = min(max(target.origin.y, barrier.minY), barrier.maxY - target.height)
        case .absorbEdge:
            target.origin.x = target.midX > barrier.midX
                ? barrier.maxX - target.width
                : barrier.minX
            // 吸附到水平边界后，纵向仍需回到可视范围内
            target.origin.y = min(max(target.origin.y, barrier.minY), barrier.maxY - target.height)
        }

        guard target != frame else {
            dragDidEnd()
            return
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            frame = target
            dragDidEnd()
            return
        }

        // allowUserInteraction 必须给：否则动画期间手柄收不到 pan，拖不动
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction]
        ) {
            self.frame = target
        } completion: { _ in
            self.dragDidEnd()
        }
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isDraggable, superview != nil else { return }

        switch gesture.state {
        case .began:
            // 上一次归位动画可能还没跑完。模型值已经是动画终点，直接用它会让手柄
            // 先瞬移到终点再跟着手指走——所以从「屏幕上实际所在的位置」接着拖。
            // 先写模型、再移除动画，presentation 就会跟到新位置。
            if let presented = layer.presentation() {
                frame.origin = presented.frame.origin
            }
            layer.removeAllAnimations()

            isDragging = true
            hasDragged = true
            frameOriginAtDragBegin = frame.origin
            dragDidBegin()

        case .changed:
            // 参考系用 superview（固定），与 frame.origin 的坐标系一致。
            // 拖动过程中不做夹取——允许拖出父视图。
            let translation = gesture.translation(in: superview)
            frame.origin = CGPoint(
                x: frameOriginAtDragBegin.x + translation.x,
                y: frameOriginAtDragBegin.y + translation.y
            )
            dragDidUpdate(offset: translation)

        case .ended, .cancelled, .failed:
            isDragging = false
            settle()

        default:
            break
        }
    }
}
