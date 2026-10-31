//
//  HierarchyViewController.swift
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

    class HierarchyViewController: UIViewController {

        private lazy var borderView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.layer.borderWidth = 2
            return v
        }()

        private lazy var pickerView: DO.HierarchyPickerView = {
            let v = DO.HierarchyPickerView(frame: .zero)
            v.delegate = self
            return v
        }()

        private lazy var infoView: DO.HierarchyInfoView = {
            let v = DO.HierarchyInfoView(frame: .zero)
            v.delegate = self
            return v
        }()

        private lazy var infoContainer = DO.DraggableLayoutView(contentView: infoView)

        private lazy var alignRulerView = DO.HierarchyAlignRulerView(frame: .zero)

        private lazy var colorLoupeView = DO.HierarchyColorLoupeView(frame: .zero)

        private var observeViews = NSMutableSet()
        private var borderViews: [Int: UIView] = [:]

        private var snapshot: UIImage?

        private var isDragging = false

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear

            view.addSubview(alignRulerView)
            view.addSubview(colorLoupeView)
            view.addSubview(infoContainer)
            view.addSubview(borderView)
            view.addSubview(pickerView)

            let pickerSize = pickerView.sizeThatFits(view.bounds.size)
            pickerView.frame = CGRect(
                x: (view.bounds.width - pickerSize.width) / 2,
                y: (view.bounds.height - pickerSize.height) / 2,
                width: pickerSize.width,
                height: pickerSize.height
            )

            infoContainer.frame = CGRect(x: 12.0, y: view.bounds.height, width: 0, height: 0)
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            alignRulerView.frame = view.bounds
    //         refreshAlignRuler()

            let width = view.bounds.width - (12.0 * 2.0)

            let height = infoContainer.sizeThatFits(CGSize(width: width, height: 0)).height

            guard infoContainer.frame.size.height != height else { return }

            infoContainer.frame = CGRect(
                x: infoContainer.frame.origin.x,
                y: infoContainer.frame.origin.y,
                width: width,
                height: height
            )

            infoContainer.settle()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            snapshot = DO.ScreenSampler.snapshot(of: DO.HierarchyPlugin.shared.appWindow)
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

        private func beginObserving(_ view: UIView, borderWidth: CGFloat) {
            guard !observeViews.contains(view) else { return }

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

        private var shouldShowRulerLines: Bool {
            let config = DO.HierarchyPlugin.shared.config
            return config.isAlignRulerEnabled && config.rulerVisibility.isVisible(whileDragging: isDragging)
        }

        private var shouldShowLoupe: Bool {
            let config = DO.HierarchyPlugin.shared.config
            return config.isColorPickEnabled && config.loupeVisibility.isVisible(whileDragging: isDragging)
        }

        private func refreshAlignRuler() {
            alignRulerView.isHidden = !shouldShowRulerLines

            guard DO.HierarchyPlugin.shared.config.isAlignRulerEnabled else {
                infoView.updateRulerInfo(nil)
                return
            }

            alignRulerView.update(center: pickerView.center)
            infoView.updateRulerInfo(alignRulerView.infoText)
        }

        private func refreshChromeVisibility() {
            alignRulerView.isHidden = !shouldShowRulerLines

            if shouldShowLoupe {
                colorLoupeView.present(animated: true)
            } else {
                colorLoupeView.dismiss(animated: true)
            }
        }

        private func refreshAll() {
            refreshAlignRuler()
            refreshColor()
            applySelection(pickerView.selectedView())
        }

        private func refreshColor() {
            guard DO.HierarchyPlugin.shared.config.isColorPickEnabled else {
                colorLoupeView.dismiss(animated: true)
                infoView.updatePixelColor(nil)
                return
            }

            let appWindow = DO.HierarchyPlugin.shared.appWindow
            let pointInAppWindow = view.convert(pickerView.center, to: appWindow)

            infoView.updatePixelColor(DO.ScreenSampler.color(at: pointInAppWindow, in: snapshot)?.hierarchy_description)

            if shouldShowLoupe {
                colorLoupeView.update(target: pickerView.center, clearance: loupeClearance, snapshot: snapshot)
                if colorLoupeView.isHidden {
                    colorLoupeView.present(animated: true)
                }
            } else {
                colorLoupeView.dismiss(animated: true)
            }
        }

        private var loupeClearance: CGFloat {
            pickerView.bounds.height / 2 + 8.0
        }

        func registerNoResponseViews(on window: DO.OverlayWindow) {
            window.addNoResponseView(view)
            window.addNoResponseView(alignRulerView)
            window.addNoResponseView(colorLoupeView)
        }

        private func frameInLocal(for view: UIView) -> CGRect {
            guard let window = DO.HierarchyPlugin.shared.appWindow else { return .zero }
            var rect = view.convert(view.bounds, to: window)
            rect = self.view.convert(rect, from: window)
            return rect
        }

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

            let chain = ancestorChain(of: selectedView)
            for view in chain.reversed() {
                beginObserving(view, borderWidth: view === selectedView ? 2 : 1)
            }

            infoView.updateSelectedView(findSelectedView(in: chain))
        }

        private func findSelectedView(in chain: [UIView]) -> UIView? {
            if DO.HierarchyPlugin.shared.config.isIgnorePrivateClass {
                return chain.first { view in
                    !String(describing: type(of: view)).hasPrefix("_")
                }
            }
            return chain.first
        }

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
                if DO.HierarchyPlugin.shared.config.isIgnorePrivateClass {
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
                if DO.HierarchyPlugin.shared.config.isIgnorePrivateClass {
                    return !String(describing: type(of: view)).hasPrefix("_")
                }
                return true
            }
        }
    }

}

extension DO.HierarchyViewController: DO.PickerViewDelegate {

    func pickerDidBeginDrag(_ picker: DO.PickerView) {
        isDragging = true
        snapshot = DO.ScreenSampler.snapshot(of: DO.HierarchyPlugin.shared.appWindow)

        refreshColor()
    }

    func pickerDidMove(_ picker: DO.PickerView) {
        refreshAll()
    }

    func pickerDidEndDrag(_ picker: DO.PickerView) {
        isDragging = false
        refreshChromeVisibility()
    }
    
}

extension DO.HierarchyViewController: DO.HierarchyInfoViewDelegate {

    func hierarchyInfoViewDidSelectParent(_ view: DO.HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showParentSheet(selectedView)
    }

    func hierarchyInfoViewDidSelectSubview(_ view: DO.HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showSubviewSheet(selectedView)
    }

    func hierarchyInfoViewDidSelectMoreInfo(_ view: DO.HierarchyInfoView) {
        guard let selectedView = infoView.selectedView else { return }
        showHierarchyInfo(selectedView)
    }

    func hierarchyInfoViewDidSelectSetting(_ view: DO.HierarchyInfoView) {
        showSetting()
    }

    func hierarchyInfoViewDidSelectClose(_ view: DO.HierarchyInfoView) {
        DO.HierarchyPlugin.shared.hide()
    }

    private func showSetting() {
        let vc = DO.HierarchySettingViewController()

        vc.onChange = { [weak self] in
            self?.refreshAll()
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showHierarchyInfo(_ selectView: UIView) {
        let vc = DO.HierarchyDetailViewController()
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
        applySelection(view)
    }
}
