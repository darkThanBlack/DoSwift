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

    // MARK: - Metrics

    /// 面板自己的布局常量。
    ///
    /// 各子视图的**尺寸**不在这里：方块、导航栏、分组头各自实现 `sizeThatFits`，
    /// 面板问它们要。谁的高度谁负责，改一个不会牵动另一个。
    private enum Metrics {

        /// 一行放几个方块
        static let columns: Int = 3
        /// 面板左右内边距。方块列、分组标签、导航栏标题三者左边缘必须对齐
        /// （历史上方块用 8、文字用 12，差 4pt 就是没对齐）。
        ///
        /// **导航栏标题和分组标签各自硬编码了同一个 12**，没有共用常量——
        /// 那两个视图结构简单，一行 `x = 12` 肉眼就能核对；抽成跨文件常量反而
        /// 要跳出去才看得见。改这里时记得一起改
        /// `DoSwiftMenuNavigationBar` 与 `DoSwiftMenuGroupHeaderView`。
        static let horizontalPadding: CGFloat = 12
        /// 面板滚动内容的上下内边距。必须留：面板四角都是 16pt 圆角，
        /// 内容贴到顶/底会被圆角切掉一块。
        static let verticalPadding: CGFloat = 10
        /// 方块之间的横向间距
        static let tileSpacing: CGFloat = 6
        /// 列宽。**格子的尺寸归面板决定**——方块只在这个宽度里排版；
        /// 它自己的高度则由 `DoSwiftMenuTile.sizeThatFits` 回答。
        static let tileWidth: CGFloat = 64

        /// 面板宽度由列数和方块宽推出来，改 `columns` 会自动跟着变。
        /// 66 是让「沙盒浏览器」这类 5 字标题排得下的值。
        static let panelWidth: CGFloat = horizontalPadding * 2
            + tileWidth * CGFloat(columns)
            + tileSpacing * CGFloat(columns - 1)

        static let cornerRadius: CGFloat = 16
        /// 面板与安全区之间的留白
        static let verticalMargin: CGFloat = 12
        /// 面板与手柄之间的留白
        static let handleGap: CGFloat = 8
        /// 面板固定高度，超出则内部滚动。
        ///
        /// 目录写死成 5 组 37 项，内容高度（约 1060）永远超过这个值，所以「按内容算高度」
        /// 那条分支在竖屏下从来没生效过——实算就是 420。横屏才需要往下夹（iPhone 横屏
        /// 只有 375~390），夹取留在 `relayout` 里。
        static let panelHeight: CGFloat = 420
        /// 关闭动画时向停靠边外侧多移一点，免得阴影露在边上
        static let shadowMargin: CGFloat = 32
    }

    // MARK: - Public State

    weak var delegate: DoSwiftMenuPanelDelegate?

    private(set) var isOpen: Bool = false

    // MARK: - Private State

    private var menuGroups: [DoSwiftMenuGroup] = []
    private var headerViews: [DoSwiftMenuGroupHeaderView] = []
    private var tilesByGroup: [[DoSwiftMenuTile]] = []

    /// 手柄中心。存的是**输入**，不是「贴哪条边」这个派生结果——
    /// 派生值会在容器尺寸变化后过期，而输入任何时候都能对着当前容器重算。
    private var handleCenter: CGPoint = .zero

    // MARK: - Subviews

    /// 裁切容器：负责圆角。阴影在 `self.layer` 上，因为 `masksToBounds` 会连阴影一起裁掉。
    private let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        return view
    }()
    
    ///
    private lazy var navigationBar: DoSwiftMenuNavigationBar = {
        let bar = DoSwiftMenuNavigationBar()
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

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadViews(in: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadViews(in box: UIView) {
        box.backgroundColor = .clear
        // 阴影在自身图层，圆角在 contentContainer —— 两者必须分在两个视图上
        box.layer.masksToBounds = false
        box.layer.shadowColor = UIColor.black.cgColor
        box.layer.shadowOpacity = 0.22
        box.layer.shadowRadius = 20

        // 四向圆角一致，与边无关，设一次即可
        contentContainer.layer.cornerRadius = Metrics.cornerRadius
        box.addSubview(contentContainer)
        contentContainer.addSubview(navigationBar)
        contentContainer.addSubview(scrollView)

        box.isHidden = true
        box.alpha = 0
    }

    // MARK: - Layout

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

        // 阴影朝停靠边反向偏移；四向圆角后这是「边」唯一影响外观的地方
        layer.shadowOffset = CGSize(width: isDockedRight ? -4 : 4, height: 6)
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: Metrics.cornerRadius
        ).cgPath
    }

    /// 把分组头和方块按「一行 `columns` 个」摆好。
    /// 全部是 frame 计算——内容静态，一次性摆完就不再动。
    private func layoutItems() {
        let width = bounds.width
        var y: CGFloat = Metrics.verticalPadding

        // 方块高度由方块自己回答；同一种方块高度一致，取一次就够
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
            // 该组最后一行没排满也要占一整行高度
            if column != 0 {
                y += tileHeight
            }
        }

        scrollView.contentSize = CGSize(
            width: width,
            height: y + Metrics.verticalPadding
        )
    }

    // MARK: - Public Interface

    func setMenuGroups(_ groups: [DoSwiftMenuGroup]) {
        menuGroups = groups
        rebuildItems()
        setNeedsLayout()
    }

    /// 纯几何计算：决定面板多大、放在哪。贴哪条边由手柄中心现算。
    ///
    /// 尺寸、安全区全部从 `superview` 取——面板是容器根视图的直接子视图
    /// （这条不能变，见类型注释第 1 条：套一层容器会破坏事件穿透）。
    func relayout(handleFrame: CGRect) {
        guard let container = superview else { return }

        handleCenter = CGPoint(x: handleFrame.midX, y: handleFrame.midY)

        let insets = container.safeAreaInsets
        let containerBounds = container.bounds

        // 高度固定。只有横屏需要往下夹——iPhone 横屏高度只有 375~390。
        let availableHeight = containerBounds.height
            - insets.top - insets.bottom
            - Metrics.verticalMargin * 2
        let height = min(Metrics.panelHeight, availableHeight)

        // 横向：让开刘海那一侧的安全区
        let x = isDockedRight
            ? containerBounds.width - Metrics.panelWidth - insets.right
            : insets.left

        // 纵向：贴着柄展开，方向取决于手柄在上半屏还是下半屏。
        // 固定朝下会有个 bug——手柄位置偏低时，面板被安全区夹回来，
        // 顶端反而跑到手柄上方，把刚点过的那个手柄盖住。
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

    /// 贴哪条边：手柄在哪半边就贴哪条边。
    ///
    /// 计算属性而不是存储属性——它由 `handleCenter` 和容器宽度派生，
    /// 存下来就得操心什么时候失效；现算三处（x、阴影方向、关闭位移）
    /// 共用同一个表达式，也不会各写一遍写岔。
    private var isDockedRight: Bool {
        guard let container = superview else { return true }
        return handleCenter.x > container.bounds.midX
    }

    /// 关闭态：朝停靠边外侧平移。用 transform 而不是 frame，
    /// 这样动画途中触发的 `layoutSubviews`（只动 bounds）不会和动画打架。
    private func closedTransform() -> CGAffineTransform {
        let offset = Metrics.panelWidth + Metrics.shadowMargin
        return CGAffineTransform(translationX: isDockedRight ? offset : -offset, y: 0)
    }
}
