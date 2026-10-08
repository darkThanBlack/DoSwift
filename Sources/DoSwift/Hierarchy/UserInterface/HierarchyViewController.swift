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
        let size: CGFloat = 60
        let x = (view.bounds.width - size) / 2
        let y = (view.bounds.height - size) / 2
        let v = HierarchyPickerView(frame: CGRect(x: x, y: y, width: size, height: size))
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

    // MARK: - State

    private var observeViews = NSMutableSet()
    private var borderViews: [Int: UIView] = [:]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // 标尺必须先进：它在边框（会被 sendSubviewToBack）之上，但在信息面板与拾取器之下
        view.addSubview(alignRulerView)
        view.addSubview(infoContainer)
        view.addSubview(borderView)
        view.addSubview(pickerView)
        
        // 给一个大致的 origin, 让 settle() 来确保完全展示
        infoContainer.frame = CGRect(x: 12.0, y: view.bounds.height, width: 0, height: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        alignRulerView.frame = view.bounds
        refreshAlignRuler()

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

    /// 把标尺推到拾取器当前位置，并把四个距离同步到信息面板。
    ///
    /// 关掉标尺时连 Position 行一起收起来——没有标线却留着四个距离是残缺状态。
    private func refreshAlignRuler() {
        let shouldHideRuler = !HierarchyPlugin.shared.isAlignRulerEnabled
        if alignRulerView.isHidden != shouldHideRuler {
            alignRulerView.isHidden = shouldHideRuler
        }

        guard !shouldHideRuler else {
            infoView.updateRulerInfo(nil)
            return
        }

        alignRulerView.update(center: pickerView.center)
        infoView.updateRulerInfo(alignRulerView.infoText)
    }

    // MARK: - No Response

    /// 把本层里不该拦触摸的视图登记到 window 上。
    ///
    /// `vc.view` 放行之后，这一层只剩拾取器、信息面板会消费触摸，其余一律穿透到业务 App；
    /// 标尺本身已经 `isUserInteractionEnabled = false`，登记它是把意图写明。
    func registerNoResponseViews(on window: OverlayWindow) {
        window.addNoResponseView(view)
        window.addNoResponseView(alignRulerView)
    }

    // MARK: - Coordinate

    private func frameInLocal(for view: UIView) -> CGRect {
        guard let window = HierarchyPlugin.shared.appWindow else { return .zero }
        var rect = view.convert(view.bounds, to: window)
        rect = self.view.convert(rect, from: window)
        return rect
    }

    // MARK: - View Hierarchy

    private func findSelectedView(in chain: [UIView]) -> UIView? {
        if HierarchyPlugin.shared.isIgnorePrivateClass {
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
            if HierarchyPlugin.shared.isIgnorePrivateClass {
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
            if HierarchyPlugin.shared.isIgnorePrivateClass {
                return !String(describing: type(of: view)).hasPrefix("_")
            }
            return true
        }
    }
}

// MARK: - HierarchyPickerViewDelegate

extension HierarchyViewController: HierarchyPickerViewDelegate {

    func hierarchyPickerView(_ pickerView: HierarchyPickerView, didMoveTo selectedView: UIView?) {
        // 放在 guard 之前：手柄动一步就要跟一步，与有没有拾取到 view 无关
        refreshAlignRuler()

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

    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView) {
        HierarchyPlugin.shared.hide()
    }

    // MARK: - Actions

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

    private func setNewSelectView(_ view: UIView) {
        hierarchyPickerView(pickerView, didMoveTo: view)
    }
}
