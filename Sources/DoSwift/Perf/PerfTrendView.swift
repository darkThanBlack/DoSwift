//
//  PerfTrendView.swift
//  DoSwift
//

import UIKit

/// 浮窗卡片的容器：**外观 + 拖动 + 手势**，内容由两种展示形式之一来画。
///
/// 拖动与吸边全部来自 `DraggableView`（基类不碰任何视觉），这里只加卡片自己的东西
/// ——材质、圆角、阴影、位置记忆、两个手势。与 `DoSwiftMenuHandle` 同一套写法。
///
/// **不做空闲淡化**：它显示的是实时值，淡下去就没法读了。让开的方式是把位置交给用户。
final class PerfTrendView: DraggableView {

    /// 位置记忆在 UserDefaults 里的 key
    static let frameKey = "kPerfTrendFrameKey"

    weak var delegate: PerfTrendViewDelegate?

    /// 用哪一种展示形式。换样式只换内容和外壳的观感，数据一条都不动。
    var style: TrendDisplayStyle = .line {
        didSet {
            guard style != oldValue else { return }
            applyStyle()
        }
    }

    /// 长按已经触发过。用来让「长按后松手」不再触发一次单击——
    /// 靠 `tap.require(toFail: longPress)` 也能做到，但那会让**每一次**单击都等满
    /// 长按的时长，手感明显发钝。
    private var didLongPress = false

    private let lineView = TrendLineView()
    private let textView = TrendTextView()

    // MARK: - Init

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

    // MARK: - Content

    /// 画一帧。折线模式只画 `currentIndex` 那一条，文字模式一次画全部——
    /// 差异全在这里，数据层不知道有这回事。
    /// - Parameters:
    ///   - current: 折线模式要画的那一条
    ///   - all: 文字模式要列的全部（只有已开启检测的指标）
    func render(current: TrendChart?, all: [TrendChart], now: TimeInterval) {
        switch style {
        case .line:
            lineView.render(current, now: now)
        case .text:
            textView.render(all, now: now)
        }
    }

    /// 内容变了尺寸就跟着变（两种形式的宽高不同，文字还会随位数变）。
    /// 返回是否真的变了，调用方据此决定要不要重新夹回屏内。
    @discardableResult
    func sizeToFitContent() -> Bool {
        let size = sizeThatFits(superview?.bounds.size ?? .zero)
        guard size != frame.size else { return false }
        frame.size = size
        setNeedsLayout()
        return true
    }

    // MARK: - Size

    override var intrinsicContentSize: CGSize { sizeThatFits(.zero) }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        switch style {
        case .line: return lineView.sizeThatFits(size)
        case .text: return textView.sizeThatFits(size)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius: CGFloat = style == .line ? 16 : 10
        glassView.frame = bounds
        glassView.layer.cornerRadius = radius
        blurView.frame = glassView.bounds
        lineView.frame = glassView.bounds
        textView.frame = glassView.bounds

        // 圆角矩形阴影路径：不给的话系统要按图层内容推导，代价更高
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
    }

    /// 两种形式的观感不同：
    ///
    /// - 折线：系统材质 + 细描边。它要压在一张曲线和一行数值下面，材质能给一点体量。
    /// - 文字：**半透明深底 + 白字，不上模糊**。一行字要的是干脆可读；而且白字配浅色
    ///   材质在浅色业务页面上根本读不出来。
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

    // MARK: - DraggableView 钩子

    override func dragDidBegin() {
        // 拖动期间不需要额外动作。长按那条路自己会看 `isDragging`——
        // 不能在这里去置 `didLongPress`，那个标志是给「长按后抬手不要再触发单击」用的，
        // 拿来取消拖动会把紧接着的下一次单击一起吞掉。
    }

    override func dragDidEnd() {
        UserDefaults.standard.set(
            ["x": frame.origin.x, "y": frame.origin.y],
            forKey: PerfTrendView.frameKey
        )
    }

    // MARK: - Gesture

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

    // MARK: - Subviews

    /// 裁切与圆角放这一层，阴影放 `self.layer`——同一个图层上设了
    /// `masksToBounds` 会把阴影一起裁掉。
    private let glassView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }()

    /// 折线模式下用系统材质——卡片会飘在任意业务界面之上，
    /// 浅色模式下纯白就是一个没有边界的白块。
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
}

// MARK: - Delegate

protocol PerfTrendViewDelegate: AnyObject {

    /// 单击：换一个指标。**卡片不自己改状态**，改哪一个是持有者的事。
    func perfTrendViewDidTap(_ view: PerfTrendView)

    /// 长按：弹设置页。卡片只上报。
    func perfTrendViewDidLongPress(_ view: PerfTrendView)
}
