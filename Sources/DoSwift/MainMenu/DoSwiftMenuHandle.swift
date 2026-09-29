//
//  DoSwiftMenuHandle.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol DoSwiftMenuHandleDelegate: AnyObject {
    func menuHandleDidTap(_ handleView: DoSwiftMenuHandle)
    /// pan 手势真正成立时才会回调——轻点不会触发，因此这里可以直接当作
    /// 「用户开始拖动手柄」用，不需要再自己比对位移阈值。
    func menuHandleDidBeginDrag(_ handleView: DoSwiftMenuHandle)
}

// MARK: - DoSwiftMenuHandle

/// 主菜单的悬浮手柄。
///
/// 拖动与松手归位全部来自 `DraggableView`；这里只加手柄自己的东西——
/// 外观、空闲淡化、位置记忆、轻点回调。基类不含任何视觉效果。
final class DoSwiftMenuHandle: DraggableView {

    // MARK: - Properties

    weak var delegate: DoSwiftMenuHandleDelegate?

    /// 是否启用空闲淡化
    var isFadeEnabled: Bool = true

    // MARK: - Fade Properties

    private var fadeTimer: Timer?
    private var fadeCounts: Int = 0
    private let fadeDelayTime: Int = 3

    // MARK: - Subviews

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.25
        return view
    }()

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
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
        // 松手后吸附到最近的边界
        releasePolicy = .absorbEdge

        backgroundColor = .clear
        addSubview(contentView)
        contentView.addSubview(iconView)

        addGestureRecognizer(tapGesture)
        // 显式声明互斥：pan 一旦成立就让 tap 失败。
        // 之前手写 touchesMoved + tap 手势两套判定并存，中间留出过一段灰区
        // （4–10pt 位移里两边同时成立，面板先关后被重新打开）。
        tapGesture.require(toFail: panGesture)
    }

    // MARK: - Size（子类职责：基类松手后要算落点，必须能确定自身大小）

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: 44)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 44, height: 44)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = bounds
        contentView.layer.cornerRadius = bounds.height / 2

        let iconSize: CGFloat = 20
        iconView.frame = CGRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        iconView.layer.cornerRadius = iconSize / 2
    }

    // MARK: - DraggableView 钩子

    override func dragDidBegin() {
        // 拖拽期间不淡化
        fireFade(false)
        delegate?.menuHandleDidBeginDrag(self)
    }

    override func dragDidEnd() {
        // 位置记忆
        let frameDict = ["x": frame.origin.x, "y": frame.origin.y]
        UserDefaults.standard.set(frameDict, forKey: UserDefaults.handleFrameKey)
    }

    @objc private func handleTap() {
        delegate?.menuHandleDidTap(self)
    }

    // MARK: - Fade

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
        guard !isDragging else { return }

        fadeCounts -= 1
        guard fadeCounts <= 0 else { return }

        fadeTimerEnd()
    }
}

// MARK: - UserDefaults Keys

extension UserDefaults {
    static let handleFrameKey = "kMenuHandleFrameKey"
}
