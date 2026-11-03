//
//  DraggableView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/09/29
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {
    
    /// Pan gesture logic for drift and drag.
    @objc(DODraggableView)
    public class DraggableView: UIView {

        public enum ReleasePolicy {
            case stay
            case bounceBack
            case absorbEdge
        }

        public var releasePolicy: ReleasePolicy = .bounceBack

        public var isDraggable: Bool {
            get { panGesture.isEnabled }
            set { panGesture.isEnabled = newValue }
        }

        public private(set) var isDragging: Bool = false

        private(set) var hasDragged: Bool = false

        private var frameOriginAtDragBegin: CGPoint = .zero

        private(set) lazy var panGesture: UIPanGestureRecognizer = {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            return gesture
        }()

        public override init(frame: CGRect) {
            super.init(frame: frame)
            addGestureRecognizer(panGesture)
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        open func dragDidBegin() {}

        open func dragDidUpdate(offset: CGPoint) {}

        open func dragDidEnd() {}

        public func settle(animated: Bool = true) {
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

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isDraggable, superview != nil else { return }

            switch gesture.state {
            case .began:
                if let presented = layer.presentation() {
                    frame.origin = presented.frame.origin
                }
                layer.removeAllAnimations()

                isDragging = true
                hasDragged = true
                frameOriginAtDragBegin = frame.origin
                dragDidBegin()

            case .changed:
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
}
