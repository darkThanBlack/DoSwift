//
//  HierarchyViewController.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyViewController.m / .h
//

import UIKit

/// 主控制器：管理 PickerView + InfoView + 边框高亮
class HierarchyViewController: UIViewController {

    // MARK: - Subviews

    private lazy var borderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderWidth = 2
        return v
    }()

    private lazy var pickerView: HierarchyPickerView = {
        let v = HierarchyPickerView(frame: .zero)
        v.delegate = self
        return v
    }()

    /// 纯内容视图：排版归它自己，位置和大小都不归它
    private lazy var infoView: HierarchyInfoView = {
        let v = HierarchyInfoView(frame: .zero)
        v.delegate = self
        return v
    }()

    /// 承载 `infoView` 的可拖拽容器。位置由拖动决定，高度由内容决定。
    private lazy var infoContainer = DraggableLayoutView(contentView: infoView)

    /// 对齐标尺：常驻。只认一个点，不认识拾取器。
    private lazy var alignRulerView = HierarchyAlignRulerView(frame: .zero)

    /// 取色放大镜：只在拖动期间出现。同样只认一个点，不认识拾取器。
    private lazy var colorLoupeView = HierarchyColorLoupeView(frame: .zero)

    // MARK: - State

    private var observeViews = NSMutableSet()
    private var borderViews: [Int: UIView] = [:]

    /// 屏幕快照。`.began` 与打开时各截一张；不主动丢弃——放大镜设成「一直显示」时，
    /// 静止状态下还要靠它出画面。
    private var snapshot: UIImage?

    /// 是否正在拖动。标尺/放大镜的「拖动时显示」这一档靠它判断。
    private var isDragging = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // 标尺必须先进：它在边框（会被 sendSubviewToBack）之上，但在信息面板与拾取器之下。
        // 放大镜同理，且压在标尺之上——两者都可能出现在手柄上方那一块。
        view.addSubview(alignRulerView)
        view.addSubview(colorLoupeView)
        view.addSubview(infoContainer)
        view.addSubview(borderView)
        view.addSubview(pickerView)

        // 尺寸问拾取器自己；它可自由拖动，所以首帧摆到屏幕正中就够了
        let pickerSize = pickerView.sizeThatFits(view.bounds.size)
        pickerView.frame = CGRect(
            x: (view.bounds.width - pickerSize.width) / 2,
            y: (view.bounds.height - pickerSize.height) / 2,
            width: pickerSize.width,
            height: pickerSize.height
        )
        
        // 给一个大致的 origin, 让 settle() 来确保完全展示
        infoContainer.frame = CGRect(x: 12.0, y: view.bounds.height, width: 0, height: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        alignRulerView.frame = view.bounds
//         refreshAlignRuler()

        /// 宽度固定
        let width = view.bounds.width - (12.0 * 2.0)
        
        /// 计算高度
        let height = infoContainer.sizeThatFits(CGSize(width: width, height: 0)).height
        
        // 拖动时也会触发, 所以只在 1>页面进入后 2>数据变化时 放过
        guard infoContainer.frame.size.height != height else { return }
        
        // 只处理 height
        infoContainer.frame = CGRect(
            x: infoContainer.frame.origin.x,
            y: infoContainer.frame.origin.y,
            width: width,
            height: height
        )
        
        // 处理 x, y
        infoContainer.settle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 打开就先取一张：不然在第一次拖动之前，标尺、边框环和 Pixel 行全是空的。
        // 此刻浮层刚显示，业务 window 早已上屏，随手就能采。
        snapshot = ScreenSampler.snapshot(of: HierarchyPlugin.shared.appWindow)
        refreshAll()
    }

    deinit {
        for view in observeViews {
            if let v = view as? UIView {
                stopObserving(v)
            }
        }
        observeViews.removeAllObjects()
    }

    // MARK: - Observe (KVO)

    private func beginObserving(_ view: UIView, borderWidth: CGFloat) {
        guard !observeViews.contains(view) else { return }
        
        /// 绘制边框
        let bv = UIView()
        bv.isUserInteractionEnabled = false
        bv.backgroundColor = .clear
        self.view.addSubview(bv)
        self.view.sendSubviewToBack(bv)
        bv.layer.borderColor = view.hierarchy_hashColor.cgColor
        bv.layer.borderWidth = borderWidth
        bv.frame = frameInLocal(for: view)
        borderViews[view.hash] = bv

        view.addObserver(self, forKeyPath: "frame", options: [], context: nil)
        observeViews.add(view)
    }

    private func stopObserving(_ view: UIView) {
        guard observeViews.contains(view) else { return }

        let bv = borderViews[view.hash]
        bv?.removeFromSuperview()
        borderViews.removeValue(forKey: view.hash)
        view.removeObserver(self, forKeyPath: "frame")
        observeViews.remove(view)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let view = object as? UIView {
            updateOverlayIfNeeded(view)
        }
    }

    private func updateOverlayIfNeeded(_ view: UIView) {
        guard let bv = borderViews[view.hash] else { return }
        bv.frame = frameInLocal(for: view)
    }

    // MARK: - Align Ruler

    /// 标线此刻该不该显示
    private var shouldShowRulerLines: Bool {
        let config = HierarchyPlugin.shared.config
        return config.isAlignRulerEnabled && config.rulerVisibility.isVisible(whileDragging: isDragging)
    }

    /// 放大镜此刻该不该显示
    private var shouldShowLoupe: Bool {
        let config = HierarchyPlugin.shared.config
        return config.isColorPickEnabled && config.loupeVisibility.isVisible(whileDragging: isDragging)
    }

    /// 把标尺推到拾取器当前位置，并把四个距离同步到信息面板。
    ///
    /// **标线的显隐与读数分开**：`rulerVisibility = .never` 只是不画线，四个距离照旧成立，
    /// 所以 Position 行只在总开关关掉时才收起——没有标线却留着距离不算残缺，
    /// 反倒是「只要数字不要线」这种用法本来就有。
    private func refreshAlignRuler() {
        alignRulerView.isHidden = !shouldShowRulerLines

        guard HierarchyPlugin.shared.config.isAlignRulerEnabled else {
            infoView.updateRulerInfo(nil)
            return
        }

        alignRulerView.update(center: pickerView.center)
        infoView.updateRulerInfo(alignRulerView.infoText)
    }

    /// 只按当前配置与拖动状态更新浮层显隐，**不动位置**。
    ///
    /// 松手时用它而不是 `refreshAll()`：归位动画会把手柄弹回界内，位置已经变了，
    /// 而按约定标尺停在原处（要跟手得让 `DraggableView` 在归位动画期间持续发事件）。
    private func refreshChromeVisibility() {
        alignRulerView.isHidden = !shouldShowRulerLines

        if shouldShowLoupe {
            colorLoupeView.present(animated: true)
        } else {
            colorLoupeView.dismiss(animated: true)
        }
    }

    // MARK: - Color Pick

    /// 一次刷新：位置 → 取色 → 拾取结果。
    private func refreshAll() {
        refreshAlignRuler()
        refreshColor()
        applySelection(pickerView.selectedView())
    }

    /// 取手柄中心那一点的颜色，同时喂给放大镜和面板。
    ///
    /// 两者读**同一张快照、同一个点**——否则会出现「放大镜里是那个灰、读数是另一个灰」。
    private func refreshColor() {
        guard HierarchyPlugin.shared.config.isColorPickEnabled else {
            colorLoupeView.dismiss(animated: true)
            infoView.updatePixelColor(nil)
            return
        }

        // 采样点要落在业务 window 的坐标系里。浮层 window 通常与它同尺寸同原点，
        // 但那是巧合不是契约——`frameInLocal(for:)` 已经在做同样的换算。
        let appWindow = HierarchyPlugin.shared.appWindow
        let pointInAppWindow = view.convert(pickerView.center, to: appWindow)

        infoView.updatePixelColor(ScreenSampler.color(at: pointInAppWindow, in: snapshot)?.hierarchy_description)

        // 放大镜的显隐是「拖动状态 + 配置」的函数，它自己不认识拖动
        if shouldShowLoupe {
            colorLoupeView.update(target: pickerView.center, clearance: loupeClearance, snapshot: snapshot)
            if colorLoupeView.isHidden {
                colorLoupeView.present(animated: true)
            }
        } else {
            colorLoupeView.dismiss(animated: true)
        }
    }

    /// 放大镜要躲开的半径。手柄多大由它自己回答，放大镜不认识它，所以在这一层算。
    private var loupeClearance: CGFloat {
        pickerView.bounds.height / 2 + 8.0
    }

    // MARK: - No Response

    /// 把本层里不该拦触摸的视图登记到 window 上。
    ///
    /// `vc.view` 放行之后，这一层只剩拾取器、信息面板会消费触摸，其余一律穿透到业务 App；
    /// 标尺本身已经 `isUserInteractionEnabled = false`，登记它是把意图写明。
    func registerNoResponseViews(on window: OverlayWindow) {
        window.addNoResponseView(view)
        window.addNoResponseView(alignRulerView)
        window.addNoResponseView(colorLoupeView)
    }

    // MARK: - Coordinate

    private func frameInLocal(for view: UIView) -> CGRect {
        guard let window = HierarchyPlugin.shared.appWindow else { return .zero }
        var rect = view.convert(view.bounds, to: window)
        rect = self.view.convert(rect, from: window)
        return rect
    }

    // MARK: - Selection

    /// 选中项的边框环与信息面板。`nil` 表示清空。
    ///
    /// 输入是 view 而不是「手柄位置」：Parent / Subviews 列表可以指定一个**不在于手柄正对处**
    /// 的 view，所以这里必须接受任意 view。
    private func applySelection(_ selectedView: UIView?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        for view in observeViews {
            if let v = view as? UIView {
                stopObserving(v)
            }
        }
        observeViews.removeAllObjects()

        guard let selectedView = selectedView else {
            infoView.updateSelectedView(nil)
            return
        }

        // 由外向内铺：选中项 2pt，其余 1pt
        let chain = ancestorChain(of: selectedView)
        for view in chain.reversed() {
            beginObserving(view, borderWidth: view === selectedView ? 2 : 1)
        }

        infoView.updateSelectedView(findSelectedView(in: chain))
    }

    // MARK: - View Hierarchy

    private func findSelectedView(in chain: [UIView]) -> UIView? {
        if HierarchyPlugin.shared.config.isIgnorePrivateClass {
            return chain.first { view in
                !String(describing: type(of: view)).hasPrefix("_")
            }
        }
        return chain.first
    }

    /// 选中项的祖先链（含自身，不含 window 本身），由内向外
    private func ancestorChain(of view: UIView) -> [UIView] {
        var chain: [UIView] = []
        var current: UIView? = view
        while let v = current, !(v is UIWindow) {
            chain.append(v)
            current = v.superview
        }
        return chain
    }

    private func findParentViews(of selectedView: UIView) -> [UIView] {
        var views: [UIView] = []
        var current: UIView? = selectedView.superview
        while let view = current {
            if HierarchyPlugin.shared.config.isIgnorePrivateClass {
                if !String(describing: type(of: view)).hasPrefix("_") {
                    views.append(view)
                }
            } else {
                views.append(view)
            }
            current = view.superview
        }
        return views
    }

    private func findSubviews(of selectedView: UIView) -> [UIView] {
        selectedView.subviews.filter { view in
            if HierarchyPlugin.shared.config.isIgnorePrivateClass {
                return !String(describing: type(of: view)).hasPrefix("_")
            }
            return true
        }
    }
}

// MARK: - PickerViewDelegate

extension HierarchyViewController: PickerViewDelegate {

    /// 拖动起点截一次，整段拖动都读这一张。
    ///
    /// 不在每个 `.changed` 里重截：`drawHierarchy` 是整屏栅格化 + 显存回读，每帧一次
    /// 不可接受；而且取色要的就是「瞄准那一刻」的画面。
    func pickerDidBeginDrag(_ picker: PickerView) {
        isDragging = true
        snapshot = ScreenSampler.snapshot(of: HierarchyPlugin.shared.appWindow)

        // 先把画面和位置准备好再让它出现，否则第一帧会闪一个空的放大镜
        refreshColor()
    }

    func pickerDidMove(_ picker: PickerView) {
        refreshAll()
    }

    /// 位置已定。只更新显隐，不重读位置。
    ///
    /// 刻意**不重截**快照——读数就是瞄准那一刻的答案，重截只会让数字在放大镜消失之后
    /// 自己变一次，没有任何视觉解释。内容真的变了，再拖一次即可（下次 `.began` 会重截）。
    func pickerDidEndDrag(_ picker: PickerView) {
        isDragging = false
        refreshChromeVisibility()
    }
    
}

// MARK: - HierarchyInfoViewDelegate

extension HierarchyViewController: HierarchyInfoViewDelegate {

    func hierarchyInfoViewDidSelectParent(_ view: HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showParentSheet(selectedView)
    }

    func hierarchyInfoViewDidSelectSubview(_ view: HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showSubviewSheet(selectedView)
    }

    func hierarchyInfoViewDidSelectMoreInfo(_ view: HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showHierarchyInfo(selectedView)
    }

    func hierarchyInfoViewDidSelectSetting(_ view: HierarchyInfoView) {
        showSetting()
    }

    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView) {
        HierarchyPlugin.shared.hide()
    }

    // MARK: - Actions

    private func showSetting() {
        let vc = HierarchySettingViewController()

        // 配置改了要立刻反映到主界面：标线、放大镜、Pixel 行、以及「私有类」影响下的拾取结果
        vc.onChange = { [weak self] in
            self?.refreshAll()
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showHierarchyInfo(_ selectView: UIView) {
        let vc = HierarchyDetailViewController()
        vc.selectView = selectView
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showParentSheet(_ selectView: UIView) {
        let parents = findParentViews(of: selectView)
        let actions = parents.map { String(describing: type(of: $0)) }
        self.hierarchy_showActionSheet(title: "Parent Views", actions: actions, currentAction: nil) { [weak self] index in
            self?.setNewSelectView(parents[index])
        }
    }

    private func showSubviewSheet(_ selectView: UIView) {
        let subviews = findSubviews(of: selectView)
        let actions = subviews.map { String(describing: type(of: $0)) }
        self.hierarchy_showActionSheet(title: "Subviews", actions: actions, currentAction: nil) { [weak self] index in
            self?.setNewSelectView(subviews[index])
        }
    }

    /// 从 Parent / Subviews 列表里直接改选。
    private func setNewSelectView(_ view: UIView) {
        applySelection(view)
    }
}
