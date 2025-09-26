//
//  DoSwiftDriftView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol DoSwiftDriftViewDelegate: AnyObject {
    func driftViewDidTap(_ driftView: DoSwiftDriftView)
}

// MARK: - DoSwiftDriftView

/// DoSwift 悬浮按钮视图，参考 DriftView 设计
class DoSwiftDriftView: UIView {

    // MARK: - Properties

    weak var delegate: DoSwiftDriftViewDelegate?

    /// 菜单项（用于显示未读数量等）
    var menuItems: [DoSwiftMenuItem] = []

    /// 是否正在拖拽
    private var isMoving: Bool = false

    /// 触摸起始点
    private var originalPoint: CGPoint = .zero

    // MARK: - Fade Properties

    /// 是否启用淡化效果
    private let canFade: Bool = true

    /// 是否启用延迟淡化
    private let canDelay: Bool = true

    /// 淡化定时器
    private var fadeTimer: Timer?

    /// 淡化倒计时
    private var fadeCounts: Int = 0

    /// 延迟时间（秒）
    private let fadeDelayTime: Int = 3

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        fadeTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// 执行边缘吸附动画
    func fireAbsorb() {
        let parentBounds = superview?.bounds ?? UIScreen.main.bounds
        let safeInsets = superview?.safeAreaInsets ?? .zero
        let barrier = parentBounds.inset(by: safeInsets)

        let newFrame = absorbHorizontal(frame, barrier: barrier)

        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                self.frame = newFrame
            },
            completion: { _ in
                // 保存位置到 UserDefaults
                let frameDict = ["x": newFrame.origin.x, "y": newFrame.origin.y]
                UserDefaults.standard.set(frameDict, forKey: DoSwiftUserDefaults.driftFrameKey)
                UserDefaults.standard.synchronize()
            }
        )
    }

    /// 执行淡化效果
    func fireFade(_ isFade: Bool) {
        guard canFade else { return }

        if isFade {
            UIView.animate(withDuration: 0.5) {
                self.alpha = 0.3
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1.0
            }
            fadeTimerRestart()
        }
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 56, height: 56)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 56, height: 56)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // contentView 填满整个 bounds
        contentView.frame = bounds

        // 设置 iconView 的 frame - 居中显示
        if let iconView = contentView.subviews.first {
            let iconSize: CGFloat = 24
            iconView.frame = CGRect(
                x: (bounds.width - iconSize) / 2,
                y: (bounds.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
        }
    }

    // MARK: - Private Methods

    private func setupView() {
        backgroundColor = .clear
        addSubview(contentView)
    }

    // MARK: - Content View

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 28  // 56/2
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.25

        // 添加图标色块 - 使用 frame 布局
        let iconView = UIView()
        iconView.backgroundColor = UIColor.white
        iconView.layer.cornerRadius = 12  // 24/2
        view.addSubview(iconView)

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true

        return view
    }()

    @objc private func handleTap() {
        delegate?.driftViewDidTap(self)
    }

    // MARK: - Fade Timer

    private func fadeTimerRestart() {
        fadeCounts = fadeDelayTime

        guard fadeTimer == nil, canDelay else { return }

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.fadeTimerEvent(timer)
        }
    }

    private func fadeTimerEnd() {
        fadeCounts = 0
        fadeTimer?.invalidate()
        fadeTimer = nil

        fireFade(true)
    }

    private func fadeTimerEvent(_ timer: Timer?) {
        guard !isMoving else { return }

        fadeCounts -= 1
        guard fadeCounts <= 0 else { return }

        fadeTimerEnd()
    }

    // MARK: - Touch Events

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }

        originalPoint = point
        isMoving = true

        fireFade(false)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }

        var newFrame = frame
        newFrame.origin.x += (point.x - originalPoint.x)
        newFrame.origin.y += (point.y - originalPoint.y)

        frame = newFrame
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        fireAbsorb()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        fireAbsorb()
    }

    // MARK: - Frame Calculations

    /// 边界限制
    private func frameInside(value: CGRect, barrier: CGRect) -> CGRect {
        var newFrame = value

        if newFrame.origin.x < barrier.minX {
            newFrame.origin.x = barrier.minX
        }

        if newFrame.origin.x > (barrier.maxX - newFrame.size.width) {
            newFrame.origin.x = barrier.maxX - newFrame.size.width
        }

        if newFrame.origin.y < barrier.minY {
            newFrame.origin.y = barrier.minY
        }

        if newFrame.origin.y > (barrier.maxY - newFrame.size.height) {
            newFrame.origin.y = barrier.maxY - newFrame.size.height
        }

        return newFrame
    }

    /// 横向吸附
    private func absorbHorizontal(_ value: CGRect, barrier: CGRect) -> CGRect {
        var newFrame = frameInside(value: value, barrier: barrier)

        if newFrame.midX > barrier.midX {
            // 吸附到右边
            newFrame.origin.x = barrier.maxX - newFrame.size.width
        } else {
            // 吸附到左边
            newFrame.origin.x = barrier.minX
        }

        return newFrame
    }
}

// MARK: - UserDefaults Keys

enum DoSwiftUserDefaults {
    static let driftFrameKey = "kDoSwiftDriftFrameKey"
}
