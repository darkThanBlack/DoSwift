//
//  HierarchyAlignRulerView.swift
//  DoSwift
//
//  Translated from DoraemonViewAlignView.m / .h
//

import UIKit

/// 对齐标尺覆盖层：由拾取器中心引出水平/垂直两条标线，并标出中心点到四条屏幕边缘的绝对距离。
///
/// **全屏、非交互。** DoKit 原版是全屏 view 加在 key window 上，靠重写 `pointInside:` 只对
/// 拾取器图标返回 YES 来放行其余触摸；我们这边 `OverlayWindow.hitTest` 是**同一性判断**——
/// `root.view` 内任何被命中的子视图都会拦下触摸，所以全屏覆盖层必须整体
/// `isUserInteractionEnabled = false`，否则整个 App 点不动。
///
/// 它只知道一个点：`update(center:)`。不认识拾取器、不认识拖动，便于别处复用。
final class HierarchyAlignRulerView: UIView {

    /// 标线颜色。原版用 `#FF0000`；不用 `.systemRed` 是因为这一层压在任意业务内容上，
    /// 深色模式下 systemRed 会偏亮偏粉，标尺要的是恒定可辨的纯红。
    static let alignColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

    /// 四个方向的绝对距离文本，例：`L 196.5  R 196.5  T 426.0  B 426.0`
    private(set) var infoText = ""

    /// 标尺交叉点（本视图坐标系）
    private var crossPoint: CGPoint = .zero

    /// 线宽取 1 物理像素。原版硬编码 0.5pt，在 3x 屏上是 1.5px，会糊。
    private var lineThickness: CGFloat { 1.0 / UIScreen.main.scale }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        addSubview(horizontalLine)
        addSubview(verticalLine)
        addSubview(leftLabel)
        addSubview(topLabel)
        addSubview(rightLabel)
        addSubview(bottomLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    /// 移动标尺交叉点。
    ///
    /// - Parameter center: 本视图坐标系下的点。本视图与 `HierarchyPickerView` 是同一父视图的
    ///   兄弟且 frame 相同，所以 `pickerView.center` 可以原样传进来，无需换算。
    func update(center: CGPoint) {
        guard bounds.width > 0, bounds.height > 0 else { return }

        crossPoint = center

        let t = lineThickness
        horizontalLine.frame = CGRect(x: 0, y: center.y - t / 2, width: bounds.width, height: t)
        verticalLine.frame = CGRect(x: center.x - t / 2, y: 0, width: t, height: bounds.height)

        applyLabels()
    }

    // MARK: - Labels

    /// 四个距离标签。
    ///
    /// 位置沿用原版：左/右标签的 x 取所在那段水平区间的中点、y 顶在水平线上方；
    /// 上/下标签的 y 取所在那段垂直区间的中点、x 顶在垂直线左侧。
    /// 原版不夹紧也不做防碰撞，拾取器贴边时标签会被切掉——这里保持原样。
    private func applyLabels() {
        let w = bounds.width
        let h = bounds.height
        let cx = crossPoint.x
        let cy = crossPoint.y

        leftLabel.text = String(format: "%.1f", cx)
        rightLabel.text = String(format: "%.1f", w - cx)
        topLabel.text = String(format: "%.1f", cy)
        bottomLabel.text = String(format: "%.1f", h - cy)

        [leftLabel, rightLabel, topLabel, bottomLabel].forEach { $0.sizeToFit() }

        leftLabel.frame.origin = CGPoint(x: cx / 2, y: cy - leftLabel.bounds.height)
        rightLabel.frame.origin = CGPoint(x: cx + (w - cx) / 2, y: cy - rightLabel.bounds.height)
        topLabel.frame.origin = CGPoint(x: cx - topLabel.bounds.width, y: cy / 2)
        bottomLabel.frame.origin = CGPoint(x: cx - bottomLabel.bounds.width, y: cy + (h - cy) / 2)

        infoText = String(format: "L %.1f  R %.1f  T %.1f  B %.1f", cx, w - cx, cy, h - cy)
    }

    // MARK: - Views

    private lazy var horizontalLine = makeLine()
    private lazy var verticalLine = makeLine()

    private lazy var leftLabel = makeLabel()
    private lazy var rightLabel = makeLabel()
    private lazy var topLabel = makeLabel()
    private lazy var bottomLabel = makeLabel()

    private func makeLine() -> UIView {
        let view = UIView()
        view.backgroundColor = HierarchyAlignRulerView.alignColor
        return view
    }

    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = HierarchyAlignRulerView.alignColor
        return label
    }
}
