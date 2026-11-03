//
//  PerfTrendView.swift
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

    @objc(DOPerfTrendView)
    final class PerfTrendView: DO.DraggableView {

        static let frameKey = "kPerfTrendFrameKey"

        weak var delegate: DO.PerfTrendViewDelegate?

        var style: DO.TrendDisplayStyle = .line {
            didSet {
                guard style != oldValue else { return }
                applyStyle()
            }
        }

        private var didLongPress = false

        private let lineView = DO.TrendLineView()
        private let textView = DO.TrendTextView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupView() {
            releasePolicy = .absorbEdge

            backgroundColor = .clear
            layer.masksToBounds = false
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.25

            addSubview(glassView)
            glassView.addSubview(blurView)
            glassView.addSubview(lineView)
            glassView.addSubview(textView)

            addGestureRecognizer(tapGesture)
            addGestureRecognizer(longPressGesture)

            applyStyle()
        }

        func render(current: DO.TrendChart?, all: [DO.TrendChart], now: TimeInterval) {
            switch style {
            case .line:
                lineView.render(current, now: now)
            case .text:
                textView.render(all, now: now)
            }
        }

        @discardableResult
        func sizeToFitContent() -> Bool {
            let size = sizeThatFits(superview?.bounds.size ?? .zero)
            guard size != frame.size else { return false }
            frame.size = size
            setNeedsLayout()
            return true
        }

        override var intrinsicContentSize: CGSize { sizeThatFits(.zero) }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            switch style {
            case .line: return lineView.sizeThatFits(size)
            case .text: return textView.sizeThatFits(size)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let radius: CGFloat = style == .line ? 16 : 10
            glassView.frame = bounds
            glassView.layer.cornerRadius = radius
            blurView.frame = glassView.bounds
            lineView.frame = glassView.bounds
            textView.frame = glassView.bounds

            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        }

        private func applyStyle() {
            let isLine = (style == .line)
            lineView.isHidden = !isLine
            textView.isHidden = isLine
            blurView.isHidden = !isLine
            glassView.backgroundColor = isLine ? .clear : UIColor.black.withAlphaComponent(0.62)
            glassView.layer.borderColor = isLine ? UIColor.separator.cgColor : UIColor.clear.cgColor
            glassView.layer.borderWidth = isLine ? 0.5 : 0

            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }

        override func dragDidBegin() {
        }

        override func dragDidEnd() {
            UserDefaults.standard.set(
                ["x": frame.origin.x, "y": frame.origin.y],
                forKey: DO.PerfTrendView.frameKey
            )
        }

        private lazy var tapGesture: UITapGestureRecognizer = {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            return gesture
        }()

        private lazy var longPressGesture: UILongPressGestureRecognizer = {
            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            gesture.minimumPressDuration = 0.5
            return gesture
        }()

        @objc private func handleTap() {
            guard !didLongPress else {
                didLongPress = false
                return
            }
            delegate?.perfTrendViewDidTap(self)
        }

        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, !isDragging else { return }
            didLongPress = true
            delegate?.perfTrendViewDidLongPress(self)
        }

        private let glassView: UIView = {
            let view = UIView()
            view.clipsToBounds = true
            view.layer.borderWidth = 0.5
            view.layer.borderColor = UIColor.separator.cgColor
            return view
        }()

        private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    }

    protocol PerfTrendViewDelegate: AnyObject {

        func perfTrendViewDidTap(_ view: DO.PerfTrendView)

        func perfTrendViewDidLongPress(_ view: DO.PerfTrendView)
    }
}
