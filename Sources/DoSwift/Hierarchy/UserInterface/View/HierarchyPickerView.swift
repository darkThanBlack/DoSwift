//
//  HierarchyPickerView.swift
//  DoSwift
//
//  Translated from DKHierarchyPickerView.m / DKHierarchyPickerView.h
//

import UIKit

protocol HierarchyPickerViewDelegate: AnyObject {
    func hierarchyPickerView(_ view: HierarchyPickerView, didMoveTo selectedViews: [UIView]?)
}

/// 可拖拽的视图拾取器
class HierarchyPickerView: PickerView {

    weak var delegate: HierarchyPickerViewDelegate?

    override func dragDidUpdate(offset: CGPoint) {
        let views = viewsForSelection(at: center)
        delegate?.hierarchyPickerView(self, didMoveTo: views)
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

    /// 找到指定坐标处可选择的视图数组
    func viewsForSelection(at pointInWindow: CGPoint) -> [UIView] {
        // 业务 window 已由 DoSwiftCore.start(appWindow:) 注入，无需再遍历所有 window 猜目标。
        //
        // 原版（DoKit-iOS）无业务 window 注入，故遍历所有 window 逐个 hitTest 定位目标：
        //   var windowForSelection: UIWindow? = keyWindow
        //   for window in HierarchyHelper.shared.allWindowsIgnorePrefix("Doraemon").reversed() {
        //       if window.hitTest(pointInWindow, with: nil) != nil {
        //           windowForSelection = window
        //           break
        //       }
        //   }
        // 恢复该逻辑的场景：不注入业务 window、或需支持多 window（含键盘/alert）拾取。
        guard let targetWindow = HierarchyHelper.shared.businessWindow else { return [] }

        if #available(iOS 26.0, *) {
            let topVC = Self.topMostViewController(targetWindow.rootViewController)
            guard let topVC = topVC else { return [] }
            let pointInTop = topVC.view.convert(pointInWindow, from: targetWindow)
            return recursiveSubviews(at: pointInTop, in: topVC.view, skipHidden: true)
        } else {
            return recursiveSubviews(at: pointInWindow, in: targetWindow, skipHidden: true)
        }
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
