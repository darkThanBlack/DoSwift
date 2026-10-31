//
//  HierarchyColorLoupeView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/10
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    final class HierarchyColorLoupeView: UIView {

        private static let sampleCount: CGFloat = 11
        private static let cellSize: CGFloat = 8
        private static let rimInset: CGFloat = 1.5
        static let diameter: CGFloat = sampleCount * cellSize

        private var target: CGPoint = .zero
        private var snapshot: UIImage?

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .clear
            isOpaque = false
            isUserInteractionEnabled = false
            isHidden = true
            alpha = 0
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

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
                if finished && self.alpha == 0 {
                    self.isHidden = true
                }
            }
        }

        private func layout(around target: CGPoint, clearance: CGFloat) {
            guard let container = superview else { return }

            let size = CGSize(width: Self.diameter, height: Self.diameter)

            var origin = CGPoint(x: target.x - size.width / 2,
                                 y: target.y - clearance - size.height)
            if origin.y < container.bounds.minY {
                origin.y = target.y + clearance
            }
            origin.x = min(max(origin.x, container.bounds.minX),
                           max(container.bounds.minX, container.bounds.maxX - size.width))

            frame = CGRect(origin: origin, size: size)
        }

        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else { return }

            drawSample(context)
            drawGrid(context)
            drawRims(context)
        }

        private func drawSample(_ context: CGContext) {
            context.saveGState()
            defer { context.restoreGState() }

            context.addEllipse(in: bounds.insetBy(dx: Self.rimInset, dy: Self.rimInset))
            context.clip()

            guard let cgImage = snapshot?.cgImage else {
                context.setFillColor(UIColor.black.withAlphaComponent(0.35).cgColor)
                context.fill(bounds)
                return
            }

            context.interpolationQuality = .none

            let half = (Self.sampleCount - 1) / 2
            let region = CGRect(
                x: target.x.rounded(.down) - half,
                y: target.y.rounded(.down) - half,
                width: Self.sampleCount,
                height: Self.sampleCount
            )

            let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            let visible = region.intersection(imageBounds)
            guard !visible.isEmpty, let crop = cgImage.cropping(to: visible) else { return }

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

            let center = CGFloat(count / 2) * Self.cellSize
            let cell = CGRect(x: center, y: center, width: Self.cellSize, height: Self.cellSize)
            context.setLineWidth(hairline)
            context.setStrokeColor(UIColor.black.cgColor)
            context.stroke(cell.insetBy(dx: -hairline, dy: -hairline))
            context.setStrokeColor(UIColor.white.cgColor)
            context.stroke(cell)
        }

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
}
