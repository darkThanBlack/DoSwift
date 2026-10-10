//
//  HierarchyColorLoupeView.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/10.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 取色放大镜：把取样点周围的一小片像素放大到肉眼可辨。
///
/// 它解决的是**手指遮挡**——屏幕上看不清 1pt 描边究竟在哪一格。因此：
///
/// - 只认一个点（`update(target:clearance:snapshot:)`），不认识手柄、不认识拖动；
/// - 位置自己算，**优先落在取样点上方**，指尖不盖住准星；
/// - 只在拖动期间出现，生命周期天然受手势约束，所以不需要额外的显隐开关。
///
/// 采样范围是 11×11 个**逻辑点**，每格 8pt，整数 8 倍。刻意不做非整数倍放大、
/// 也不做平滑——平滑会把「这一点是什么颜色」变成「这点附近平均是什么颜色」，
/// 而那个平均的核由 CoreGraphics 隐式决定，说不清也写不到界面上。
final class HierarchyColorLoupeView: UIView {

    // MARK: - Metrics

    /// 采样范围边长，取奇数：中心那一格正好是取样点自己
    private static let sampleCount: CGFloat = 11
    /// 每格边长（点）
    private static let cellSize: CGFloat = 8
    /// 圆环中心线的内缩量
    private static let rimInset: CGFloat = 1.5
    /// 直径 = 11 × 8
    static let diameter: CGFloat = sampleCount * cellSize

    // MARK: - State

    /// 取样点（父视图坐标系），即手柄中心
    private var target: CGPoint = .zero
    /// 本次拖动的那张屏幕快照
    private var snapshot: UIImage?

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        isOpaque = false
        // 纯展示层：不消费触摸，也不拦触摸
        isUserInteractionEnabled = false
        isHidden = true
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    /// 跟随取样点。位置与画面一起更新，调用方只需在每次位置变化时叫一次。
    ///
    /// - Parameters:
    ///   - target: 取样点（父视图坐标系）。
    ///   - clearance: 需要避开的半径。指尖和手柄盖住多大范围由调用方给——本视图不认识
    ///     手柄，也就不知道它多大。
    ///   - snapshot: 本次拖动的快照。**必须与面板读数共用同一张**，否则会出现
    ///     「放大镜里是那个灰、读数是另一个灰」。
    func update(target: CGPoint, clearance: CGFloat, snapshot: UIImage?) {
        self.target = target
        self.snapshot = snapshot

        layout(around: target, clearance: clearance)
        setNeedsDisplay()
    }

    func present(animated: Bool) {
        isHidden = false

        let changes = { self.alpha = 1.0 }
        guard animated else {
            changes()
            return
        }
        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState], animations: changes)
    }

    func dismiss(animated: Bool) {
        let changes = { self.alpha = 0.0 }

        guard animated else {
            changes()
            isHidden = true
            return
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: changes) { finished in
            // 淡出期间又被叫起来（连续两次拖动之间）就别藏了，否则会闪一下
            if finished && self.alpha == 0 {
                self.isHidden = true
            }
        }
    }

    // MARK: - Layout

    private func layout(around target: CGPoint, clearance: CGFloat) {
        guard let container = superview else { return }

        let size = CGSize(width: Self.diameter, height: Self.diameter)

        // 优先放在上方
        var origin = CGPoint(x: target.x - size.width / 2,
                             y: target.y - clearance - size.height)
        // 上方放不下就整块翻到下方
        if origin.y < container.bounds.minY {
            origin.y = target.y + clearance
        }
        // 水平夹进容器：贴边时不至于整个露到屏幕外
        origin.x = min(max(origin.x, container.bounds.minX),
                       max(container.bounds.minX, container.bounds.maxX - size.width))

        frame = CGRect(origin: origin, size: size)
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        drawSample(context)
        drawGrid(context)
        drawRims(context)
    }

    /// 把 11×11 个点铺满整个视图，每格 `cellSize`。
    private func drawSample(_ context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        // 只画圆内：方形的四角会越过圆环，不裁的话能看见像素露在外面
        context.addEllipse(in: bounds.insetBy(dx: Self.rimInset, dy: Self.rimInset))
        context.clip()

        guard let cgImage = snapshot?.cgImage else {
            context.setFillColor(UIColor.black.withAlphaComponent(0.35).cgColor)
            context.fill(bounds)
            return
        }

        // 最近邻：每格由一个源像素放大而来，不做任何插值
        context.interpolationQuality = .none

        // 与读数一致：向下取整到所在像素，中心格才真的是「读到的那个点」
        let half = (Self.sampleCount - 1) / 2
        let region = CGRect(
            x: target.x.rounded(.down) - half,
            y: target.y.rounded(.down) - half,
            width: Self.sampleCount,
            height: Self.sampleCount
        )

        // 采样区用 CGImage 自己的像素坐标（左上为原点），与 `UIImage.size` 同为 1x。
        // 贴边时采样区会有一部分落在图像外：只画交叠部分，缺的部分留空。
        let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let visible = region.intersection(imageBounds)
        guard !visible.isEmpty, let crop = cgImage.cropping(to: visible) else { return }

        // 用 `UIImage.draw(in:)` 而不是 `CGContext.draw(_:in:)`：
        //
        // UIKit 的绘制上下文是 y 向下的，而 `CGContextDrawImage` 按「图像第一行落在
        // rect 的上边」理解这个坐标系，于是在 y 向下的上下文里画出来**上下颠倒**。
        // `UIImage` 的绘制语义则明确是「图像左上角落在 rect 左上角」，与上下文无关。
        // 放大倍数靠上面那句 `interpolationQuality = .none` 保住，不受此影响。
        UIImage(cgImage: crop).draw(in: CGRect(
            x: (visible.minX - region.minX) * Self.cellSize,
            y: (visible.minY - region.minY) * Self.cellSize,
            width: visible.width * Self.cellSize,
            height: visible.height * Self.cellSize
        ))
    }

    private func drawGrid(_ context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        context.addEllipse(in: bounds.insetBy(dx: Self.rimInset, dy: Self.rimInset))
        context.clip()

        let hairline = 1.0 / UIScreen.main.scale
        // 中灰在亮底和暗底上都读得出来；纯黑或纯白总会有一半内容上看不见
        context.setStrokeColor(UIColor(white: 0.5, alpha: 0.25).cgColor)
        context.setLineWidth(hairline)

        let count = Int(Self.sampleCount)
        for index in 1..<count {
            let offset = CGFloat(index) * Self.cellSize
            context.move(to: CGPoint(x: offset, y: 0))
            context.addLine(to: CGPoint(x: offset, y: bounds.height))
            context.move(to: CGPoint(x: 0, y: offset))
            context.addLine(to: CGPoint(x: bounds.width, y: offset))
        }
        context.strokePath()

        // 中心格 = 面板读数对应的那一个点。白线压一线黑，
        // 保证在任何底色上都还看得见框
        let center = CGFloat(count / 2) * Self.cellSize
        let cell = CGRect(x: center, y: center, width: Self.cellSize, height: Self.cellSize)
        context.setLineWidth(hairline)
        context.setStrokeColor(UIColor.black.cgColor)
        context.stroke(cell.insetBy(dx: -hairline, dy: -hairline))
        context.setStrokeColor(UIColor.white.cgColor)
        context.stroke(cell)
    }

    /// 内外两圈：任意底色上都要看得清边界（原版做法——黑线打底，白线压在上面）
    private func drawRims(_ context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        let path = UIBezierPath(ovalIn: bounds.insetBy(dx: Self.rimInset, dy: Self.rimInset))

        context.setLineWidth(3)
        context.setStrokeColor(UIColor.black.cgColor)
        context.addPath(path.cgPath)
        context.strokePath()

        context.setLineWidth(1.5)
        context.setStrokeColor(UIColor.white.cgColor)
        context.addPath(path.cgPath)
        context.strokePath()
    }
}
