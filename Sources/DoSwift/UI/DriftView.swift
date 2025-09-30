//
//  DriftView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol DriftViewDelegate: AnyObject {
    func driftViewDidTap(_ driftView: DriftView)
    func driftViewDidBeginDrag(_ driftView: DriftView)
    func driftViewDidDrag(_ driftView: DriftView, location: CGPoint)
    func driftViewDidEndDrag(_ driftView: DriftView, location: CGPoint)
}

// MARK: - DriftView

/// 纯拖拽组件，不持有业务逻辑
class DriftView: UIView {

    // MARK: - Properties

    weak var delegate: DriftViewDelegate?

    /// 是否启用边缘吸附
    var isEdgeAbsorbEnabled: Bool = true

    /// 是否启用淡化效果
    var isFadeEnabled: Bool = true

    /// 是否可拖拽
    var isDragEnabled: Bool = true

    /// 是否正在拖拽
    private var isMoving: Bool = false

    /// 触摸起始点
    private var originalPoint: CGPoint = .zero

    // MARK: - Fade Properties

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
        guard isEdgeAbsorbEnabled else { return }

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
                UserDefaults.standard.set(frameDict, forKey: UserDefaults.driftFrameKey)
                UserDefaults.standard.synchronize()
            }
        )
    }

    /// 执行淡化效果
    func fireFade(_ isFade: Bool) {
        guard isFadeEnabled else { return }

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
        return CGSize(width: 44, height: 44)  // 56→44
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 44, height: 44)  // 56→44
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // contentView 填满整个 bounds
        contentView.frame = bounds

        // 设置圆角 - 根据控件高度动态计算
        contentView.layer.cornerRadius = bounds.height / 2  // 44/2=22

        // 设置 iconView 的 frame - 居中显示
        if let iconView = contentView.subviews.first {
            let iconSize: CGFloat = 20  // 24→20，按比例缩小
            iconView.frame = CGRect(
                x: (bounds.width - iconSize) / 2,
                y: (bounds.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            // 图标圆角也动态计算
            iconView.layer.cornerRadius = iconSize / 2  // 20/2=10
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
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.25

        // 添加图标色块 - 使用 frame 布局
        let iconView = UIView()
        iconView.backgroundColor = UIColor.white
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
        guard isFadeEnabled else { return }

        fadeCounts = fadeDelayTime

        guard fadeTimer == nil else { return }

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
        guard isDragEnabled, let point = touches.first?.location(in: self) else { return }

        originalPoint = point
        isMoving = true

        fireFade(false)
        delegate?.driftViewDidBeginDrag(self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragEnabled, let point = touches.first?.location(in: self) else { return }

        var newFrame = frame
        newFrame.origin.x += (point.x - originalPoint.x)
        newFrame.origin.y += (point.y - originalPoint.y)

        // 自由拖拽模式下，限制中心点不超出边界
        if !isEdgeAbsorbEnabled {
            let parentBounds = superview?.bounds ?? UIScreen.main.bounds
            let safeInsets = superview?.safeAreaInsets ?? .zero
            let barrier = parentBounds.inset(by: safeInsets)

            // 计算中心点位置
            let centerX = newFrame.midX
            let centerY = newFrame.midY

            // 限制中心点在边界内
            let minCenterX = barrier.minX + newFrame.width / 2
            let maxCenterX = barrier.maxX - newFrame.width / 2
            let minCenterY = barrier.minY + newFrame.height / 2
            let maxCenterY = barrier.maxY - newFrame.height / 2

            if centerX < minCenterX {
                newFrame.origin.x = barrier.minX
            } else if centerX > maxCenterX {
                newFrame.origin.x = barrier.maxX - newFrame.width
            }

            if centerY < minCenterY {
                newFrame.origin.y = barrier.minY
            } else if centerY > maxCenterY {
                newFrame.origin.y = barrier.maxY - newFrame.height
            }
        }

        frame = newFrame

        // 通知代理拖拽位置变化
        let center = CGPoint(x: newFrame.midX, y: newFrame.midY)
        let locationInSuperview = superview?.convert(center, to: nil) ?? center
        delegate?.driftViewDidDrag(self, location: locationInSuperview)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragEnabled else { return }

        isMoving = false

        let center = CGPoint(x: frame.midX, y: frame.midY)
        let locationInSuperview = superview?.convert(center, to: nil) ?? center
        delegate?.driftViewDidEndDrag(self, location: locationInSuperview)

        fireAbsorb()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragEnabled else { return }

        isMoving = false

        let center = CGPoint(x: frame.midX, y: frame.midY)
        let locationInSuperview = superview?.convert(center, to: nil) ?? center
        delegate?.driftViewDidEndDrag(self, location: locationInSuperview)

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

extension UserDefaults {
    static let driftFrameKey = "kDriftFrameKey"
}
