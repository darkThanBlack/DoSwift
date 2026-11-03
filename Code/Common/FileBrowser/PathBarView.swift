//
//  PathBarView.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// What the bar asks: how many items, and what each one is.
    protocol PathBarViewDataSource: AnyObject {

        /// Depth including the root.
        func pathBarItemNumbers(_ bar: DO.PathBarView) -> Int

        /// Item at `index` (0 = root); only `nodeName` is read.
        func pathBar(_ bar: DO.PathBarView, itemFor index: Int) -> any DO.PathNode
    }

    /// What the bar reports: which item was tapped.
    protocol PathBarViewDelegate: AnyObject {

        /// Return false to swallow the tap.
        func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool

        /// An item was tapped; `canSelectAt` already said yes.
        func pathBar(_ bar: DO.PathBarView, didSelectAt index: Int)
    }

    /// Scrollable breadcrumb with faded edges. Knows only counts, indices and taps —
    /// where you actually are lives in the business path stack.
    @objc(DOPathBarView)
    final class PathBarView: UIView {

        weak var dataSource: (any DO.PathBarViewDataSource)?

        weak var delegate: (any DO.PathBarViewDelegate)?

        /// Item currently shown at `index` (separators excluded).
        private(set) var itemViews: [UILabel] = []

        /// Re-asks the data source and scrolls right; a reload always means something changed.
        func reloadData() {
            reload()

            scrollToTail()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            loadViews(in: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func handleTap(gesture: UITapGestureRecognizer) {
            /// Hit-test only the items we built; separators and spacing ignore taps.
            guard let index = itemViews.firstIndex(where: { $0.bounds.contains(gesture.location(in: $0)) }) else { return }

            /// Whether a tap counts is a delegate decision — ask, then report.
            guard (delegate?.pathBar(self, canSelectAt: index) ?? true) else { return }

            delegate?.pathBar(self, didSelectAt: index)
        }

        // MARK: - Views

        /// Leading / trailing inset.
        private let contentInset: CGFloat = 16.0

        private func loadViews(in box: UIView) {
            box.backgroundColor = DO.FileBrowserStyle.backgroundColor

            box.addSubview(scrollView)
            box.addSubview(leftFade)
            box.addSubview(rightFade)

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            leftFade.translatesAutoresizingMaskIntoConstraints = false
            rightFade.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: box.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: box.bottomAnchor),

                leftFade.topAnchor.constraint(equalTo: box.topAnchor),
                leftFade.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                leftFade.bottomAnchor.constraint(equalTo: box.bottomAnchor),
                leftFade.widthAnchor.constraint(equalToConstant: contentInset),

                rightFade.topAnchor.constraint(equalTo: box.topAnchor),
                rightFade.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                rightFade.bottomAnchor.constraint(equalTo: box.bottomAnchor),
                rightFade.widthAnchor.constraint(equalToConstant: contentInset),
            ])

            scrollView.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: contentInset),
                stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -contentInset),
                stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
                stack.heightAnchor.constraint(greaterThanOrEqualToConstant: 36.0),
            ])

            /// Hug above the default 250 so the content area cannot stretch the bar.
            setContentHuggingPriority(.defaultHigh, for: .vertical)

            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:))))
        }

        /// Height comes from the content (`36` as floor); width is up to the caller.
        ///
        /// `UIStackView` reports `(-1, -1)`, so the bar must supply its own height.
        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: max(36.0, contentHeight()))
        }

        /// Natural height: the tallest of separators and labels.
        private func contentHeight() -> CGFloat {
            var height: CGFloat = 0.0
            for view in stack.arrangedSubviews {
                height = max(height, view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
            }
            return height
        }

        /// Scroll to the end. Measure with `systemLayoutSizeFitting`; `contentSize` is stale
        /// right after adding a subview.
        private func scrollToTail() {
            let viewport: CGFloat = bounds.width
            guard viewport > 0.0 else { return }

            let contentWidth: CGFloat = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
                + contentInset * 2.0
            guard contentWidth > viewport else { return }

            scrollView.setContentOffset(CGPoint(x: contentWidth - viewport, y: 0.0), animated: false)
        }

        /// Rebuilt every time — the bar is a pure view layer over the data source.
        private func reload() {
            stack.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            itemViews.removeAll()

            defer { invalidateIntrinsicContentSize() }

            guard let ds = dataSource else { return }

            let numbers: Int = ds.pathBarItemNumbers(self)

            for index in 0..<numbers {
                if index > 0 {
                    let sep = makeSeparator()
                    stack.addArrangedSubview(sep)
                    sep.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        sep.widthAnchor.constraint(equalToConstant: 9.0),
                        sep.heightAnchor.constraint(equalToConstant: 12.0),
                    ])
                }

                let label = makeItem(node: ds.pathBar(self, itemFor: index), isCurrent: index == numbers - 1)
                stack.addArrangedSubview(label)
                label.setContentHuggingPriority(.required, for: .horizontal)
                label.widthAnchor.constraint(lessThanOrEqualToConstant: 200.0).isActive = true
                itemViews.append(label)
            }
        }

        private func makeItem(node: any DO.PathNode, isCurrent: Bool) -> UILabel {
            let label = UILabel()
            // Non-empty default so the label keeps a width.
            label.text = {
                if let n = node.nodeName, n.isEmpty == false {
                    return n
                }
                return " - "
            }()
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingMiddle  // keep the tail visible
            label.font = DO.FileBrowserStyle.pathFont(isCurrent: isCurrent)
            label.textColor = isCurrent ? DO.FileBrowserStyle.themeColor : DO.FileBrowserStyle.lightTextColor
            return label
        }

        private func makeSeparator() -> UIImageView {
            let view = UIImageView(image: DO.FileBrowserStyle.arrowImage())
            view.contentMode = .scaleAspectFit
            view.tintColor = DO.FileBrowserStyle.disabledTextColor
            view.isUserInteractionEnabled = false
            return view
        }

        private lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.showsHorizontalScrollIndicator = false
            view.showsVerticalScrollIndicator = false
            view.bounces = false
            view.contentInsetAdjustmentBehavior = .never
            view.backgroundColor = .clear
            return view
        }()

        private lazy var stack: UIStackView = {
            let view = UIStackView()
            view.axis = .horizontal
            view.alignment = .center
            view.distribution = .fill
            view.spacing = 6.0
            return view
        }()

        /// Leading fade: background to clear, pinned to the viewport edge.
        private lazy var leftFade = FadeView(
            background: DO.FileBrowserStyle.backgroundColor,
            reversed: false
        )

        /// Trailing fade.
        private lazy var rightFade = FadeView(
            background: DO.FileBrowserStyle.backgroundColor,
            reversed: true
        )
    }
}

extension DO.PathBarViewDelegate {

    /// Always allowed by default.
    func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool {
        return true
    }
}

extension DO.PathBarView {

    /// Fade mask.
    @objc(DOPathBarViewFadeView)
    private final class FadeView: UIView {

        override class var layerClass: AnyClass {
            return CAGradientLayer.self
        }

        init(background: UIColor, reversed: Bool) {
            super.init(frame: .zero)

            isUserInteractionEnabled = false

            let clear: UIColor = background.withAlphaComponent(0.0)
            let gradient = layer as? CAGradientLayer
            gradient?.colors = (reversed ? [clear, background] : [background, clear]).map({ $0.cgColor })
            gradient?.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient?.endPoint = CGPoint(x: 1.0, y: 0.5)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
