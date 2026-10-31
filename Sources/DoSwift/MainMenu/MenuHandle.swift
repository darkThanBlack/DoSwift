//
//  DO.MenuHandle.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

extension DO {

    // MARK: - Delegate Protocol

    protocol MenuHandleDelegate: AnyObject {
        func menuHandleDidTap(_ handleView: DO.MenuHandle)
        func menuHandleDidBeginDrag(_ handleView: DO.MenuHandle)
    }

    // MARK: - DO.MenuHandle

    final class MenuHandle: DO.DraggableView {

        // MARK: - Constants

        static let handleFrameKey = "kMenuHandleFrameKey"

        // MARK: - Properties

        weak var delegate: DO.MenuHandleDelegate?

        var isFadeEnabled: Bool = true {
            didSet {
                guard isFadeEnabled != oldValue else { return }

                if isFadeEnabled {
                    fadeCounts = fadeDelayTime     // 恢复：从满额重新计数
                } else {
                    showHandle()                   // 暂停：立刻回到不透明
                }
            }
        }

        // MARK: - Fade Properties

        private var fadeTimer: Timer?
        private var fadeCounts: Int = 0
        private let fadeDelayTime: Int = 3

        // MARK: - Subviews

        private let glassView: UIView = {
            let view = UIView()
            view.clipsToBounds = true
            view.layer.borderWidth = 0.5
            view.layer.borderColor = UIColor.separator.cgColor
            return view
        }()

        private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

        private let iconView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.tintColor = .label
            view.image = UIImage(systemName: "wrench")
            return view
        }()

        private lazy var tapGesture: UITapGestureRecognizer = {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            return gesture
        }()

        // MARK: - Initializers

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupView()
        }

        deinit {
            fadeTimer?.invalidate()
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
            glassView.addSubview(iconView)

            fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.idleTick()
            }

            addGestureRecognizer(tapGesture)
            tapGesture.require(toFail: panGesture)
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: 44, height: 44)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: 44, height: 44)
        }

        // MARK: - Layout

        override func layoutSubviews() {
            super.layoutSubviews()

            glassView.frame = bounds
            glassView.layer.cornerRadius = bounds.height / 2
            blurView.frame = glassView.bounds

            let iconSize: CGFloat = 20
            iconView.frame = CGRect(
                x: (bounds.width - iconSize) / 2,
                y: (bounds.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        }

        // MARK: - Trait

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)

            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
            glassView.layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
        }

        override func dragDidBegin() {
            showHandle()
            delegate?.menuHandleDidBeginDrag(self)
        }

        override func dragDidEnd() {
            let frameDict = ["x": frame.origin.x, "y": frame.origin.y]
            UserDefaults.standard.set(frameDict, forKey: DO.MenuHandle.handleFrameKey)
        }

        @objc private func handleTap() {
            delegate?.menuHandleDidTap(self)
        }

        // MARK: - Fade

        private func showHandle() {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1.0
            }
            fadeCounts = fadeDelayTime
        }

        private func dimHandle() {
            UIView.animate(withDuration: 0.5) {
                self.alpha = 0.3
            }
        }

        private func idleTick() {
            guard isFadeEnabled, !isDragging else { return }

            fadeCounts -= 1
            guard fadeCounts <= 0 else { return }

            dimHandle()
            fadeCounts = fadeDelayTime   // 淡完自己填满：空闲淡化是循环，不是一次性
        }
    }
}
