//
//  HierarchyPickerView.swift
//  DoSwift
//
//  Translated from DKHierarchyPickerView.m / DKHierarchyPickerView.h
//

import UIKit

protocol HierarchyPickerViewDelegate: AnyObject {
    func hierarchyPickerView(_ view: HierarchyPickerView, didMoveTo selectedView: UIView?)
}

/// 可拖拽的视图拾取器
class HierarchyPickerView: PickerView {

    /// 查找方式。两种实现并行保留在下面，改这一行来回切换对比。
    enum SearchStrategy {
        /// 复刻 OC「组件检查」(`DoraemonViewCheckView`) 的查找：window 起步，pointInside 判据
        case viewCheck
        /// 先求 topMost VC，再从它的 view 往下下降（DoKit `02e1f72` 在 iOS 26 上的做法）
        case topViewController
    }

    var searchStrategy: SearchStrategy = .viewCheck

    weak var delegate: HierarchyPickerViewDelegate?

    override func dragDidUpdate(offset: CGPoint) {
        delegate?.hierarchyPickerView(self, didMoveTo: selectedView())
    }

    /// 手柄正对的那个 view
    func selectedView() -> UIView? {
        switch searchStrategy {
        case .viewCheck:
            return viewByViewCheck(at: center)
        case .topViewController:
            return viewByTopViewController(at: center)
        }
    }

    /// 业务 window 已由 `DoSwiftCore.start(appWindow:)` 注入，无需再遍历所有 window 猜目标。
    ///
    /// 原版（DoKit-iOS）无注入，故遍历所有 window 逐个 hitTest 定位目标：
    ///   var windowForSelection: UIWindow? = keyWindow
    ///   for window in HierarchyHelper.shared.allWindowsIgnorePrefix("Doraemon").reversed() {
    ///       if window.hitTest(pointInWindow, with: nil) != nil {
    ///           windowForSelection = window
    ///           break
    ///       }
    ///   }
    /// 恢复该逻辑的场景：不注入业务 window、或需支持多 window（含键盘/alert）拾取。
    private var targetWindow: UIWindow? {
        HierarchyHelper.shared.businessWindow
    }

    // MARK: - Strategy A · 组件检查

    /// 复刻 `DoraemonViewCheckView` 的 `-topView:Point:` / `-hitTest:Point:`
    ///
    /// 与策略 B 的实质差别只有一条：判据是 `point(inside:with:)`（OC 的 `pointInside:withEvent:`），
    /// 且一旦为假就整棵剪掉；B 走的是 `frame.contains` + `convert`，并对
    /// `clipsToBounds == false` 的视图强行下探（FLEX 的溢出子视图语义）。
    ///
    /// 原版还排除了自身与红框 `_viewBound`（`![view isDescendantOfView:self]`）；
    /// 拾取器不在被搜的 window 里，故这里不需要。
    private func viewByViewCheck(at pointInWindow: CGPoint) -> UIView? {
        guard let targetWindow = targetWindow else { return nil }
        var hits: [UIView] = []
        collectByViewCheck(pointInWindow, in: targetWindow, into: &hits)
        return hits.last
    }

    /// 对应 OC 的 `-hitTest:Point:`
    private func collectByViewCheck(_ point: CGPoint, in view: UIView, into hits: inout [UIView]) {
        var point = point
        if let scrollView = view as? UIScrollView {
            // OC 靠手算 `point - subview.frame.origin` 往下传点，丢了 bounds.origin，
            // 所以这里要把 contentOffset 补回去，点进了 bounds 空间才能喂给 pointInside；
            // 对 scrollView 而言 bounds.origin 就是 contentOffset。
            point.x += scrollView.contentOffset.x
            point.y += scrollView.contentOffset.y
        }

        guard view.point(inside: point, with: nil), !view.isHidden, view.alpha >= 0.01 else { return }

        hits.append(view)

        for subview in view.subviews {
            let subPoint = CGPoint(x: point.x - subview.frame.origin.x,
                                   y: point.y - subview.frame.origin.y)
            collectByViewCheck(subPoint, in: subview, into: &hits)
        }
    }

    // MARK: - Strategy B · topViewController

    /// 搜索空间被限制在 topMost VC 一棵子树内
    private func viewByTopViewController(at pointInWindow: CGPoint) -> UIView? {
        guard let targetWindow = targetWindow,
              let topVC = Self.topMostViewController(targetWindow.rootViewController) else { return nil }
        let pointInTopView = topVC.view.convert(pointInWindow, from: targetWindow)
        return recursiveSubviews(at: pointInTopView, in: topVC.view, skipHidden: true).last
    }

    // MARK: - View Finding

    /// 找到顶层 ViewController
    private static func topMostViewController(_ vc: UIViewController?) -> UIViewController? {
        guard let vc = vc else { return nil }
        if let presented = vc.presentedViewController {
            return topMostViewController(presented)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(selected)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMostViewController(visible)
        }
        if let page = vc as? UIPageViewController, page.viewControllers?.count == 1 {
            return topMostViewController(page.viewControllers?.first)
        }
        for subview in vc.view.subviews {
            if let childVC = subview.next as? UIViewController {
                return topMostViewController(childVC)
            }
        }
        return vc
    }

    /// 递归查找最深层次的可点击视图
    func recursiveSubviews(at pointInView: CGPoint, in view: UIView, skipHidden: Bool) -> [UIView] {
        var results: [UIView] = []

        for subview in view.subviews {
            let isHidden = subview.isHidden || subview.alpha < 0.01
            if skipHidden && isHidden { continue }

            let containsPoint = subview.frame.contains(pointInView)
            if containsPoint {
                results.append(subview)
            }

            if containsPoint || !subview.clipsToBounds {
                let pointInSubview = view.convert(pointInView, to: subview)
                results.append(contentsOf: recursiveSubviews(at: pointInSubview, in: subview, skipHidden: skipHidden))
            }
        }

        return results
    }
}
