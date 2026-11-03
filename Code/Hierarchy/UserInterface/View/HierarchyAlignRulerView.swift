//
//  HierarchyAlignRulerView.swift
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

    @objc(DOHierarchyAlignRulerView)
    final class HierarchyAlignRulerView: UIView {

        static let alignColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        private(set) var infoText = ""

        private var crossPoint: CGPoint = .zero

        private var lineThickness: CGFloat { 1.0 / UIScreen.main.scale }

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

        func update(center: CGPoint) {
            guard bounds.width > 0, bounds.height > 0 else { return }

            crossPoint = center

            let t = lineThickness
            horizontalLine.frame = CGRect(x: 0, y: center.y - t / 2, width: bounds.width, height: t)
            verticalLine.frame = CGRect(x: center.x - t / 2, y: 0, width: t, height: bounds.height)

            applyLabels()
        }

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

        private lazy var horizontalLine = makeLine()
        private lazy var verticalLine = makeLine()

        private lazy var leftLabel = makeLabel()
        private lazy var rightLabel = makeLabel()
        private lazy var topLabel = makeLabel()
        private lazy var bottomLabel = makeLabel()

        private func makeLine() -> UIView {
            let view = UIView()
            view.backgroundColor = DO.HierarchyAlignRulerView.alignColor
            return view
        }

        private func makeLabel() -> UILabel {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.textColor = DO.HierarchyAlignRulerView.alignColor
            return label
        }
    }
}
