//
//  DoSwiftMenuPanel.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 贴边主菜单面板，替代原先居中弹出的 `DoSwiftMenuViewController`。
///
/// 三条设计约束，改动前务必先读：
///
/// 1. **非模态**。不设遮罩，轨以外的触摸照常穿透到业务 App。这不是额外实现出来的——
///    `OverlayWindow.hitTest` 只对「恰好等于注册视图」的命中返回 nil，而面板是
///    `root.view` 的直接子视图，于是轨外的触摸会一路冒泡到 `root.view` 被判定穿透。
///    **因此这个视图不能套任何全屏容器**：容器会成为命中视图且未注册，
///    结果是整个 App 点不动。
/// 2. **无状态**。只认 `DoSwiftMenuGroup`，不知道任何工具的存在，也不显示任何工具的
///    运行状态——每个插件各自持有并管理自己的 window。
/// 3. **扁平**。分组即 DoKit 的模块，没有二级菜单。
///
/// 实现上是 `UIScrollView` + 一次性摆好所有方块。37 项全部是静态数据，建好之后
/// 内容不再变化，所以既不需要 table view 的复用机制，也不需要数据源/代理那一套。
protocol DoSwiftMenuPanelDelegate: AnyObject {
    /// 选中了某个工具。面板自身不执行任何行为。
    func menuPanel(_ panel: DoSwiftMenuPanel, didSelect item: DoSwiftMenuItem)

    /// 点了导航栏的关闭按钮。
    ///
    /// 面板只上报，**不自己收起**——收起动作必须走外部的唯一入口，
    /// 那里还要同步手柄的空闲淡化状态。面板自己调 `hide()` 会绕过它，
    /// 结果就是面板关了、手柄却永久停在「不淡化」。
    func menuPanelDidSelectClose(_ panel: DoSwiftMenuPanel)
}

final class DoSwiftMenuPanel: UIView {

    /// 停靠边
    enum Edge {
        case left
        case right
    }

    // MARK: - Public State

    weak var delegate: DoSwiftMenuPanelDelegate?

    private(set) var isOpen: Bool = false

    // MARK: - Private State

    private var menuGroups: [DoSwiftMenuGroup] = []
    private var headerViews: [DoSwiftMenuGroupHeaderView] = []
    private var tilesByGroup: [[DoSwiftMenuTile]] = []
    private var edge: Edge = .right

    // MARK: - Subviews

    /// 裁切容器：负责圆角。阴影在 `self.layer` 上，因为 `masksToBounds` 会连阴影一起裁掉。
    private let contentContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    /// 顶部固定栏：一个标题 + 一个关闭按钮。不随内容滚动。
    private lazy var navigationBar: DoSwiftMenuNavigationBar = {
        let bar = DoSwiftMenuNavigationBar()
        bar.onClose = { [weak self] in
            guard let self = self else { return }
            self.delegate?.menuPanelDidSelectClose(self)
        }
        return bar
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        // 这个滚动视图不是某个 VC 的根视图，但仍会从自身所处位置推导
        // adjustedContentInset，不关掉的话内容会被状态栏高度顶下去。
        view.contentInsetAdjustmentBehavior = .never
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        // 阴影在自身图层，圆角在 contentContainer —— 两者必须分在两个视图上
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 20

        addSubview(contentContainer)
        contentContainer.addSubview(blurView)
        contentContainer.addSubview(navigationBar)
        contentContainer.addSubview(scrollView)

        isHidden = true
        alpha = 0
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        contentContainer.frame = bounds
        blurView.frame = contentContainer.bounds

        let barHeight = DoSwiftMenuMetrics.headerBarHeight
        navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: barHeight)
        scrollView.frame = CGRect(
            x: 0,
            y: barHeight,
            width: bounds.width,
            height: max(0, bounds.height - barHeight)
        )

        layoutItems()
        applyEdgeStyle()
    }

    /// 把分组头和方块按「一行 `columns` 个」摆好。
    /// 全部是 frame 计算——内容静态，一次性摆完就不再动。
    private func layoutItems() {
        let width = bounds.width
        var y: CGFloat = DoSwiftMenuMetrics.verticalPadding

        for (groupIndex, _) in menuGroups.enumerated() {
            guard groupIndex < headerViews.count, groupIndex < tilesByGroup.count else { break }

            headerViews[groupIndex].frame = CGRect(
                x: 0, y: y, width: width, height: DoSwiftMenuMetrics.groupHeaderHeight
            )
            y += DoSwiftMenuMetrics.groupHeaderHeight

            var column = 0
            for tile in tilesByGroup[groupIndex] {
                tile.frame = CGRect(
                    x: DoSwiftMenuMetrics.horizontalPadding
                        + CGFloat(column) * (DoSwiftMenuMetrics.tileWidth + DoSwiftMenuMetrics.tileSpacing),
                    y: y,
                    width: DoSwiftMenuMetrics.tileWidth,
                    height: DoSwiftMenuMetrics.tileHeight
                )
                column += 1
                if column == DoSwiftMenuMetrics.columns {
                    column = 0
                    y += DoSwiftMenuMetrics.tileHeight
                }
            }
            // 该组最后一行没排满也要占一整行高度
            if column != 0 {
                y += DoSwiftMenuMetrics.tileHeight
            }
        }

        scrollView.contentSize = CGSize(
            width: width,
            height: y + DoSwiftMenuMetrics.verticalPadding
        )
    }

    /// 圆角只圆朝外的一侧，阴影路径与之对齐。
    private func applyEdgeStyle() {
        let radius = DoSwiftMenuMetrics.cornerRadius
        contentContainer.layer.cornerRadius = radius

        let uiCorners: UIRectCorner
        let maskedCorners: CACornerMask
        if edge == .right {
            // 贴在屏幕右侧 → 圆左边两角
            uiCorners = [.topLeft, .bottomLeft]
            maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else {
            uiCorners = [.topRight, .bottomRight]
            maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
        contentContainer.layer.maskedCorners = maskedCorners

        layer.shadowOffset = CGSize(width: edge == .right ? -4 : 4, height: 6)
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: uiCorners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath
    }

    // MARK: - Public Interface

    func setMenuGroups(_ groups: [DoSwiftMenuGroup]) {
        menuGroups = groups
        rebuildItems()
        setNeedsLayout()
    }

    /// 纯几何计算：决定面板贴哪条边、多大、放在哪。
    ///
    /// 高度是**算出来的**，不去问 `scrollView.contentSize`——
    /// 面板尺寸要先确定，内部的滚动内容才有尺寸可言。
    func relayout(edge: Edge, handleFrame: CGRect, containerBounds: CGRect, safeAreaInsets: UIEdgeInsets) {
        self.edge = edge

        let availableHeight = containerBounds.height
            - safeAreaInsets.top - safeAreaInsets.bottom
            - DoSwiftMenuMetrics.verticalMargin * 2
        // 导航栏是固定高度，不参与滚动，所以面板高度 = 导航栏 + 滚动内容
        let totalContentHeight = DoSwiftMenuMetrics.headerBarHeight + contentHeight
        let height = max(
            DoSwiftMenuMetrics.minimumPanelHeight,
            min(totalContentHeight, DoSwiftMenuMetrics.maxPanelHeight, max(DoSwiftMenuMetrics.minimumPanelHeight, availableHeight))
        )

        // 横向：让开刘海那一侧的安全区
        let dockInset = edge == .right ? safeAreaInsets.right : safeAreaInsets.left
        let x = edge == .right
            ? containerBounds.width - DoSwiftMenuMetrics.panelWidth - dockInset
            : dockInset

        // 纵向：贴着柄展开，方向取决于手柄在上半屏还是下半屏。
        // 固定朝下会有个 bug——手柄位置偏低时，面板被安全区夹回来，
        // 顶端反而跑到手柄上方，把刚点过的那个手柄盖住。
        let minY = safeAreaInsets.top + DoSwiftMenuMetrics.verticalMargin
        let maxY = containerBounds.height - safeAreaInsets.bottom - DoSwiftMenuMetrics.verticalMargin - height
        let opensDownward = handleFrame.midY < containerBounds.midY
        let preferredY = opensDownward
            ? handleFrame.maxY + DoSwiftMenuMetrics.handleGap
            : handleFrame.minY - DoSwiftMenuMetrics.handleGap - height
        let y = min(max(preferredY, minY), max(minY, maxY))

        frame = CGRect(x: x, y: y, width: DoSwiftMenuMetrics.panelWidth, height: height)
        setNeedsLayout()
    }

    func show(animated: Bool) {
        guard !isOpen else { return }

        #if DEBUG
        // 触发条件写错的话整个 App 会点不动，这里主动拦一道
        assert(
            superview != nil && frame != superview!.bounds,
            "[MenuPanel] 面板必须是容器的直接子视图，且 frame 不能等于容器 bounds，否则事件穿透会被破坏"
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
            // 关键：隐藏后 hitTest 会跳过这个视图，面板原来的区域才能真正穿透回 App
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

    // MARK: - Private

    /// 建出全部分组头和方块。只在目录变化时跑一次。
    private func rebuildItems() {
        headerViews.forEach { $0.removeFromSuperview() }
        tilesByGroup.forEach { $0.forEach { $0.removeFromSuperview() } }
        headerViews = []
        tilesByGroup = []

        for group in menuGroups {
            let header = DoSwiftMenuGroupHeaderView(
                title: group.title,
                showsTopHairline: !headerViews.isEmpty
            )
            scrollView.addSubview(header)
            headerViews.append(header)

            var tiles: [DoSwiftMenuTile] = []
            for item in group.items {
                let tile = DoSwiftMenuTile()
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

    private var contentHeight: CGFloat {
        let rows = menuGroups.reduce(0) { partial, group in
            partial + (group.items.count + DoSwiftMenuMetrics.columns - 1) / DoSwiftMenuMetrics.columns
        }
        return DoSwiftMenuMetrics.verticalPadding * 2
            + CGFloat(menuGroups.count) * DoSwiftMenuMetrics.groupHeaderHeight
            + CGFloat(rows) * DoSwiftMenuMetrics.tileHeight
    }

    /// 关闭态：朝停靠边外侧平移。用 transform 而不是 frame，
    /// 这样动画途中触发的 `layoutSubviews`（只动 bounds）不会和动画打架。
    private func closedTransform() -> CGAffineTransform {
        let offset = DoSwiftMenuMetrics.panelWidth + DoSwiftMenuMetrics.shadowMargin
        return CGAffineTransform(translationX: edge == .right ? offset : -offset, y: 0)
    }
}

// MARK: - Group Header View

/// 分组头。刻意不用 `UITableViewHeaderFooterView`——本仓库的既有写法就是把普通
/// `UIView` 交给代理（见 `DoSwiftPropertyHeaderView`）。
final class DoSwiftMenuGroupHeaderView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let hairline: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    init(title: String, showsTopHairline: Bool) {
        super.init(frame: .zero)
        backgroundColor = .clear
        titleLabel.text = title
        hairline.isHidden = !showsTopHairline
        addSubview(hairline)
        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DoSwiftMenuMetrics.horizontalPadding
        hairline.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)
        titleLabel.frame = CGRect(
            x: inset,
            y: 0,
            width: max(0, bounds.width - inset * 2),
            height: bounds.height
        )
    }
}

// MARK: - Navigation Bar

/// 主菜单面板顶部的固定栏：标题 + 关闭按钮。
///
/// 关闭按钮存在的意义是给面板一个**明确的出口**。面板是非模态的、没有遮罩，
/// 所以没有「点外部关闭」；之前唯一的出口是再点一次手柄，不够显而易见。
final class DoSwiftMenuNavigationBar: UIView {

    /// 关闭按钮回调
    var onClose: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "DoSwift"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        // 不指定配置的话，符号会按按钮默认字号（约 17pt）渲染，在这个窄面板里太重
        let symbol = UIImage.SymbolConfiguration(
            pointSize: DoSwiftMenuMetrics.closeButtonSymbolSize,
            weight: .medium
        )
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbol), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()

    private let hairline: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(hairline)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DoSwiftMenuMetrics.horizontalPadding
        hairline.frame = CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5)

        let buttonSize = DoSwiftMenuMetrics.closeButtonSize
        closeButton.frame = CGRect(
            x: bounds.width - inset - buttonSize,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )

        titleLabel.frame = CGRect(
            x: inset,
            y: 0,
            width: max(0, closeButton.frame.minX - inset * 2),
            height: bounds.height
        )
    }

    @objc private func handleClose() {
        onClose?()
    }
}
