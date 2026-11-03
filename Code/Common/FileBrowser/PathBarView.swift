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

    /// 路径条的**问**（有几项 / 第 i 项是什么）
    protocol PathBarViewDataSource: AnyObject {

        /// 路径深度（含根）
        func pathBarItemNumbers(_ bar: DO.PathBarView) -> Int

        /// 第 index 层的路径项（0 = 根）；只读它的 `nodeName`
        func pathBar(_ bar: DO.PathBarView, itemFor index: Int) -> any DO.PathNode
    }

    /// 路径条的**报**（点了第几项）
    protocol PathBarViewDelegate: AnyObject {

        /// 返回 false 阻止这次点击（不上报）
        func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool

        /// 已经点了某一项（当前层是否算数由 ``canSelectAt`` 决定）
        func pathBar(_ bar: DO.PathBarView, didSelectAt index: Int)
    }

    /// 文件路径条：从左到右可滚动、可点击，边缘渐隐。只认「几项 / 第 i 项 / 点了第几项」，
    /// 自己一个数据字段都不存 —— 「现在在哪几层」只有业务那份路径栈。
    @objc(DOPathBarView)
    final class PathBarView: UIView {

        weak var dataSource: (any DO.PathBarViewDataSource)?

        weak var delegate: (any DO.PathBarViewDelegate)?

        /// 当前展示的第 i 项（下标与 dataSource 对齐；分隔符不在其中）
        private(set) var itemViews: [UILabel] = []

        /// 重新问一遍数据源并对齐到最右 —— 上游重排本身就意味着刷新过，不做「没变就别动」。
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
            /// 命中判定只看自己造出来的 item（分隔符 / 间距不在里面，点了自然没反应）
            guard let index = itemViews.firstIndex(where: { $0.bounds.contains(gesture.location(in: $0)) }) else { return }

            /// 点哪一项算不算数（包括「当前层点了要做什么」）是上层策略：这里只问、只报
            guard (delegate?.pathBar(self, canSelectAt: index) ?? true) else { return }

            delegate?.pathBar(self, didSelectAt: index)
        }

        // MARK: - Views

        /// 首尾留白
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

            /// 垂直 hugging 抬到 250（默认值）之上，免得同层的内容区把整条拉长
            setContentHuggingPriority(.defaultHigh, for: .vertical)

            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:))))
        }

        /// 条高由内容决定（`36` 兜底），宽度交给外部。
        ///
        /// 高度**必须自带固有尺寸**：`UIStackView` 的 `intrinsicContentSize` 是 `(-1, -1)`，`.center`
        /// 对齐下内容高度回传不到 `stack` / `self`；兄弟视图一有确定高度就会把它拉满剩余的。
        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: max(36.0, contentHeight()))
        }

        /// 内容的自然高度：取分隔符 / 文字里最高的那个
        private func contentHeight() -> CGFloat {
            var height: CGFloat = 0.0
            for view in stack.arrangedSubviews {
                height = max(height, view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
            }
            return height
        }

        /// 滚动到末尾。内容宽用 `systemLayoutSizeFitting` 现算，不读 `contentSize` ——
        /// 后者加子视图不标脏，实测会读到「少了一项」的旧值。
        private func scrollToTail() {
            let viewport: CGFloat = bounds.width
            guard viewport > 0.0 else { return }

            let contentWidth: CGFloat = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
                + contentInset * 2.0
            guard contentWidth > viewport else { return }

            scrollView.setContentOffset(CGPoint(x: contentWidth - viewport, y: 0.0), animated: false)
        }

        /// 每次重建：视图是框架自己造的展示层，数据一律现问数据源
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
            // 给默认值，用来确保 label.width > 0, 不会出现空节点
            label.text = {
                if let n = node.nodeName, n.isEmpty == false {
                    return n
                }
                return " - "
            }()
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingMiddle  // 中间截断
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

        /// 左侧渐隐：贴住视野左边缘，从「背景色」淡到透明
        private lazy var leftFade = FadeView(
            background: DO.FileBrowserStyle.backgroundColor,
            reversed: false
        )

        /// 右侧渐隐
        private lazy var rightFade = FadeView(
            background: DO.FileBrowserStyle.backgroundColor,
            reversed: true
        )
    }
}

extension DO.PathBarViewDelegate {

    /// 默认放行
    func pathBar(_ bar: DO.PathBarView, canSelectAt index: Int) -> Bool {
        return true
    }
}

extension DO.PathBarView {

    /// 渐隐遮罩
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
