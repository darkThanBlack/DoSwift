//
//  MenuPanel.swift
//  DoSwift
//
//  Created by moonShadow on 2026/09/28
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    protocol MenuPanelDelegate: AnyObject {
        func menuPanel(_ panel: DO.MenuPanel, didSelect item: DO.MenuItem)

        func menuPanelDidSelectClose(_ panel: DO.MenuPanel)
    }
    
    @objc(DOMenuPanel)
    final class MenuPanel: UIView {

        private enum Metrics {

            static let columns: Int = 3
            static let horizontalPadding: CGFloat = 12
            static let verticalPadding: CGFloat = 10
            static let tileSpacing: CGFloat = 6
            static let tileWidth: CGFloat = 64

            static let panelWidth: CGFloat = horizontalPadding * 2
                + tileWidth * CGFloat(columns)
                + tileSpacing * CGFloat(columns - 1)

            static let cornerRadius: CGFloat = 16
            static let verticalMargin: CGFloat = 12
            static let handleGap: CGFloat = 8
            static let panelHeight: CGFloat = 420
            static let shadowMargin: CGFloat = 32
        }

        weak var delegate: DO.MenuPanelDelegate?

        private(set) var isOpen: Bool = false

        private var menuGroups: [DO.MenuGroup] = []
        private var headerViews: [DO.MenuGroupHeaderView] = []
        private var tilesByGroup: [[DO.MenuTile]] = []

        private var handleCenter: CGPoint = .zero

        private let contentContainer: UIView = {
            let view = UIView()
            view.backgroundColor = .systemBackground
            view.clipsToBounds = true
            return view
        }()

        private lazy var navigationBar: DO.MenuNavigationBar = {
            let bar = DO.MenuNavigationBar()
            bar.onClose = { [weak self] in
                guard let self = self else { return }
                self.delegate?.menuPanelDidSelectClose(self)
            }
            return bar
        }()

        private lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.contentInsetAdjustmentBehavior = .never
            view.showsHorizontalScrollIndicator = false
            view.backgroundColor = .clear
            return view
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func loadViews(in box: UIView) {
            box.backgroundColor = .clear
            box.layer.masksToBounds = false
            box.layer.shadowColor = UIColor.black.cgColor
            box.layer.shadowOpacity = 0.22
            box.layer.shadowRadius = 20

            contentContainer.layer.cornerRadius = Metrics.cornerRadius
            box.addSubview(contentContainer)
            contentContainer.addSubview(navigationBar)
            contentContainer.addSubview(scrollView)

            box.isHidden = true
            box.alpha = 0
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            contentContainer.frame = bounds

            let barHeight = navigationBar.sizeThatFits(bounds.size).height
            navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: barHeight)
            scrollView.frame = CGRect(
                x: 0,
                y: barHeight,
                width: bounds.width,
                height: max(0, bounds.height - barHeight)
            )

            layoutItems()

            layer.shadowOffset = CGSize(width: isDockedRight ? -4 : 4, height: 6)
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: Metrics.cornerRadius
            ).cgPath
        }

        private func layoutItems() {
            let width = bounds.width
            var y: CGFloat = Metrics.verticalPadding

            let tileHeight = tilesByGroup.first?.first?
                .sizeThatFits(CGSize(width: Metrics.tileWidth, height: 0)).height ?? 0

            for (groupIndex, _) in menuGroups.enumerated() {
                guard groupIndex < headerViews.count, groupIndex < tilesByGroup.count else { break }

                let headerHeight = headerViews[groupIndex]
                    .sizeThatFits(CGSize(width: width, height: 0)).height
                headerViews[groupIndex].frame = CGRect(
                    x: 0, y: y, width: width, height: headerHeight
                )
                y += headerHeight

                var column = 0
                for tile in tilesByGroup[groupIndex] {
                    tile.frame = CGRect(
                        x: Metrics.horizontalPadding
                            + CGFloat(column) * (Metrics.tileWidth + Metrics.tileSpacing),
                        y: y,
                        width: Metrics.tileWidth,
                        height: tileHeight
                    )
                    column += 1
                    if column == Metrics.columns {
                        column = 0
                        y += tileHeight
                    }
                }
                if column != 0 {
                    y += tileHeight
                }
            }

            scrollView.contentSize = CGSize(
                width: width,
                height: y + Metrics.verticalPadding
            )
        }

        func setMenuGroups(_ groups: [DO.MenuGroup]) {
            menuGroups = groups
            rebuildItems()
            setNeedsLayout()
        }

        func relayout(handleFrame: CGRect) {
            guard let container = superview else { return }

            handleCenter = CGPoint(x: handleFrame.midX, y: handleFrame.midY)

            let insets = container.safeAreaInsets
            let containerBounds = container.bounds

            let availableHeight = containerBounds.height
                - insets.top - insets.bottom
                - Metrics.verticalMargin * 2
            let height = min(Metrics.panelHeight, availableHeight)

            let x = isDockedRight
                ? containerBounds.width - Metrics.panelWidth - insets.right
                : insets.left

            let minY = insets.top + Metrics.verticalMargin
            let maxY = containerBounds.height - insets.bottom - Metrics.verticalMargin - height
            let opensDownward = handleCenter.y < containerBounds.midY
            let preferredY = opensDownward
                ? handleFrame.maxY + Metrics.handleGap
                : handleFrame.minY - Metrics.handleGap - height
            let y = min(max(preferredY, minY), max(minY, maxY))

            frame = CGRect(x: x, y: y, width: Metrics.panelWidth, height: height)
            setNeedsLayout()
        }

        func show(animated: Bool) {
            guard !isOpen else { return }

            #if DEBUG
            assert(
                superview != nil && frame != superview!.bounds,
                "[MenuPanel] the panel must be a direct subview with a frame smaller than its container bounds, or pass-through hit testing breaks"
            )
            #endif

            isOpen = true
            isHidden = false

            guard animated, !UIAccessibility.isReduceMotionEnabled else {
                transform = .identity
                alpha = 1
                return
            }

            transform = closedTransform()
            alpha = 0
            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.4,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                self.transform = .identity
                self.alpha = 1
            }
        }

        func hide(animated: Bool, completion: (() -> Void)? = nil) {
            guard isOpen else {
                completion?()
                return
            }
            isOpen = false

            let finish = {
                self.transform = .identity
                self.alpha = 0
                self.isHidden = true
                completion?()
            }

            guard animated, !UIAccessibility.isReduceMotionEnabled else {
                finish()
                return
            }

            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                self.transform = self.closedTransform()
                self.alpha = 0
            } completion: { _ in
                finish()
            }
        }

        private func rebuildItems() {
            headerViews.forEach { $0.removeFromSuperview() }
            tilesByGroup.forEach { $0.forEach { $0.removeFromSuperview() } }
            headerViews = []
            tilesByGroup = []

            for group in menuGroups {
                let header = DO.MenuGroupHeaderView(title: group.title)
                scrollView.addSubview(header)
                headerViews.append(header)

                var tiles: [DO.MenuTile] = []
                for item in group.items {
                    let tile = DO.MenuTile()
                    tile.configure(with: item)
                    tile.onTap = { [weak self] item in
                        guard let self = self else { return }
                        self.delegate?.menuPanel(self, didSelect: item)
                    }
                    scrollView.addSubview(tile)
                    tiles.append(tile)
                }
                tilesByGroup.append(tiles)
            }
        }

        private var isDockedRight: Bool {
            guard let container = superview else { return true }
            return handleCenter.x > container.bounds.midX
        }

        private func closedTransform() -> CGAffineTransform {
            let offset = Metrics.panelWidth + Metrics.shadowMargin
            return CGAffineTransform(translationX: isDockedRight ? offset : -offset, y: 0)
        }
    }
}
