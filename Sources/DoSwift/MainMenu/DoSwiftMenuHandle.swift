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
///
/// **保持无状态**：不知道任何工具的存在，也不显示任何工具的运行状态。
/// 每个插件各自持有并管理自己的 window，手柄只负责「打开主菜单」这一件事。
final class DoSwiftMenuHandle: DraggableView {

    // MARK: - Constants

    /// 位置记忆在 UserDefaults 里的 key
    static let handleFrameKey = "kMenuHandleFrameKey"

    // MARK: - Properties

    weak var delegate: DoSwiftMenuHandleDelegate?

    /// 是否启用空闲淡化。
    ///
    /// 由**外部**驱动：主菜单展开期间置 `false`，手柄恒亮；关闭后置 `true`，从满额重新计时。
    /// 手柄自己从不写它，所以它的含义只有一层——外部要求暂停空闲淡化。
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

    /// 裁切与圆角放在这一层，阴影放在 `self.layer`——
    /// 同一个图层上设了 `masksToBounds` 会把阴影一起裁掉。
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
        // wrench：iOS 13 符号集内，且 37 个菜单方块没有一个用它，不会和工具图标混淆
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
        // 松手后吸附到最近的边界
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

        // 计时器常驻，1Hz。用完即销毁的写法没有重启者——那正是之前手柄淡下去
        // 就再也亮不回来的原因。默认 runloop mode，滚动/拖动期间会被挂起，
        // 而那几个时刻本来也不该淡化。
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.idleTick()
        }

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

        // 圆形阴影路径：不给的话系统要按图层内容推导，代价更高
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    // MARK: - Trait

    /// `borderColor` 是 `CGColor`，在 init 时就被解析成固定值，不像 `backgroundColor`
    /// 那样跟着动态色走。外观切换后必须重新解析一次，否则边框永远停在旧的那一档。
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        glassView.layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }

    // MARK: - DraggableView 钩子

    override func dragDidBegin() {
        // 拖动期间手柄必须完整可见。计数在这里填满、又在 idleTick 里被 isDragging 冻结，
        // 所以真正开始倒数是松手之后——不需要在 dragDidUpdate 里反复重置。
        showHandle()
        delegate?.menuHandleDidBeginDrag(self)
    }

    override func dragDidEnd() {
        // 位置记忆
        let frameDict = ["x": frame.origin.x, "y": frame.origin.y]
        UserDefaults.standard.set(frameDict, forKey: DoSwiftMenuHandle.handleFrameKey)
    }

    @objc private func handleTap() {
        delegate?.menuHandleDidTap(self)
    }

    // MARK: - Fade

    /// 回到不透明并重新计时。
    ///
    /// 任何「用户还在操作手柄」的时刻都该调它——「可见」在语义上本来就蕴含「重新计时」，
    /// 这两件事不该拆开给调用方选。
    private func showHandle() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
        fadeCounts = fadeDelayTime
    }

    /// 空闲到期，淡下去
    private func dimHandle() {
        UIView.animate(withDuration: 0.5) {
            self.alpha = 0.3
        }
    }

    /// 空闲跳动。计时器常驻，每秒一跳。
    private func idleTick() {
        // 暂停期间不倒数；拖动期间也不倒数——松手那一刻计数仍是满的，
        // 于是空闲时间从拖拽结束才开始算。
        guard isFadeEnabled, !isDragging else { return }

        fadeCounts -= 1
        guard fadeCounts <= 0 else { return }

        dimHandle()
        fadeCounts = fadeDelayTime   // 淡完自己填满：空闲淡化是循环，不是一次性
    }
}
