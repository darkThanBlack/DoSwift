//
//  PresentAnimation.swift
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

    final class PresentTransitioningHandler: NSObject, UIViewControllerTransitioningDelegate {

        private let animation = DO.PresentAnimation()

        func presentationController(forPresented presented: UIViewController,
                                    presenting: UIViewController?,
                                    source: UIViewController) -> UIPresentationController? {
            DO.PresentPresentationController(presentedViewController: presented, presenting: presenting)
        }

        func animationController(forPresented presented: UIViewController,
                                 presenting: UIViewController,
                                 source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            animation.to(.present)
        }

        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            animation.to(.dismiss)
        }
    }

    final class PresentPresentationController: UIPresentationController {

        private lazy var scrimView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            view.alpha = 0
            view.isUserInteractionEnabled = false
            return view
        }()

        override func presentationTransitionWillBegin() {
            guard let containerView = containerView else { return }
            scrimView.frame = containerView.bounds
            scrimView.alpha = 0
            containerView.insertSubview(scrimView, at: 0)

            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.scrimView.alpha = 1
            })
        }

        override func dismissalTransitionWillBegin() {
            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.scrimView.alpha = 0
            })
        }

        override func containerViewWillLayoutSubviews() {
            super.containerViewWillLayoutSubviews()
            scrimView.frame = containerView?.bounds ?? .zero
        }

        override var frameOfPresentedViewInContainerView: CGRect {
            containerView?.bounds ?? .zero
        }
    }

    final class PresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {

        enum Kind {
            case present
            case dismiss
        }

        private var kind: Kind?

        func to(_ kind: Kind) -> Self {
            self.kind = kind
            return self
        }

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            0.3
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let container = transitionContext.containerView
            let size = container.bounds.size

            guard let kind = kind else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }

            switch kind {
            case .present:
                guard let toView = transitionContext.view(forKey: .to) else {
                    transitionContext.completeTransition(false)
                    return
                }
                container.addSubview(toView)
                toView.frame = CGRect(x: 0, y: size.height, width: size.width, height: size.height)
                UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
                    toView.frame = container.bounds
                } completion: { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled && finished)
                }

            case .dismiss:
                guard let fromView = transitionContext.view(forKey: .from) else {
                    transitionContext.completeTransition(false)
                    return
                }
                UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
                    fromView.frame = CGRect(x: 0, y: size.height, width: size.width, height: size.height)
                } completion: { finished in
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled && finished)
                }
            }
        }
    }
}
