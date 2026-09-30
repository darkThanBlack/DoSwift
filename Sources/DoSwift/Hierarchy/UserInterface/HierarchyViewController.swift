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

    private lazy var infoView: HierarchyInfoView = {
        // 只给宽度：高度由内容算（HierarchyInfoView 自己负责尺寸），
        // 未拖动前它会自己贴到父视图底部。
        let width = view.bounds.width - 20
        let v = HierarchyInfoView(frame: CGRect(x: 10, y: 0, width: width, height: 0))
        v.delegate = self
        return v
    }()

    // MARK: - State

    private var observeViews = NSMutableSet()
    private var borderViews: [Int: UIView] = [:]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.green.withAlphaComponent(0.5)

        view.addSubview(infoView)
        view.addSubview(borderView)
        view.addSubview(pickerView)
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

        let bv = UIView()
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

    // MARK: - Coordinate

    private func frameInLocal(for view: UIView) -> CGRect {
        guard let window = HierarchyHelper.shared.businessWindow else { return .zero }
        var rect = view.convert(view.bounds, to: window)
        rect = self.view.convert(rect, from: window)
        return rect
    }

    // MARK: - View Hierarchy

    private func findSelectedView(in selectedViews: [UIView]) -> UIView? {
        if HierarchyHelper.shared.isIgnorePrivateClass {
            return selectedViews.last { view in
                !String(describing: type(of: view)).hasPrefix("_")
            }
        }
        return selectedViews.last
    }

    private func findParentViews(of selectedView: UIView) -> [UIView] {
        var views: [UIView] = []
        var current: UIView? = selectedView.superview
        while let view = current {
            if HierarchyHelper.shared.isIgnorePrivateClass {
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
            if HierarchyHelper.shared.isIgnorePrivateClass {
                return !String(describing: type(of: view)).hasPrefix("_")
            }
            return true
        }
    }
}

// MARK: - HierarchyPickerViewDelegate

extension HierarchyViewController: HierarchyPickerViewDelegate {

    func hierarchyPickerView(_ view: HierarchyPickerView, didMoveTo selectedViews: [UIView]?) {
        guard let views = selectedViews else { return }

        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        for view in observeViews {
            if let v = view as? UIView {
                stopObserving(v)
            }
        }
        observeViews.removeAllObjects()

        for (i, view) in views.enumerated().reversed() {
            let bw: CGFloat = (i == views.count - 1) ? 2 : 1
            beginObserving(view, borderWidth: bw)
        }
        observeViews.addObjects(from: views)

        infoView.updateSelectedView(findSelectedView(in: views))
    }
}

// MARK: - HierarchyInfoViewDelegate

extension HierarchyViewController: HierarchyInfoViewDelegate {

    func hierarchyInfoView(_ view: HierarchyInfoView, didSelect action: HierarchyInfoViewAction) {
        guard let selectedView = infoView.selectedView else { return }

        switch action {
        case .showMoreInfo:
            showHierarchyInfo(selectedView)
        case .showParent:
            showParentSheet(selectedView)
        case .showSubview:
            showSubviewSheet(selectedView)
        }
    }

    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView) {
        HierarchyHelper.shared.window?.hide()
        HierarchyHelper.shared.window = nil
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
        hierarchyPickerView(pickerView, didMoveTo: [view])
    }
}
