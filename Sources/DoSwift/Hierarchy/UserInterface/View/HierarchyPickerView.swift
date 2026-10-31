//
//  HierarchyPickerView.swift
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

    class HierarchyPickerView: DO.PickerView {

        enum SearchStrategy {
            case viewCheck
            case topViewController
        }

        var searchStrategy: SearchStrategy = .viewCheck

        func selectedView() -> UIView? {
            switch searchStrategy {
            case .viewCheck:
                return viewByViewCheck(at: center)
            case .topViewController:
                return viewByTopViewController(at: center)
            }
        }

        private var appWindow: UIWindow? {
            DO.HierarchyPlugin.shared.appWindow
        }

        private func viewByViewCheck(at pointInWindow: CGPoint) -> UIView? {
            guard let appWindow = appWindow else { return nil }
            var hits: [UIView] = []
            collectByViewCheck(pointInWindow, in: appWindow, into: &hits)
            return hits.last
        }

        private func collectByViewCheck(_ point: CGPoint, in view: UIView, into hits: inout [UIView]) {
            var point = point
            if let scrollView = view as? UIScrollView {
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

        private func viewByTopViewController(at pointInWindow: CGPoint) -> UIView? {
            guard let appWindow = appWindow,
                  let topVC = Self.topMostViewController(appWindow.rootViewController) else { return nil }
            let pointInTopView = topVC.view.convert(pointInWindow, from: appWindow)
            return recursiveSubviews(at: pointInTopView, in: topVC.view, skipHidden: true).last
        }

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
}
