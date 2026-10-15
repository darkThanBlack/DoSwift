//
//  PresentAnimation.swift
//  DoSwift
//
//  仿系统「底部升起」的 present 转场：代理 + 转场控制器 + 动画，三件套。
//  照搬 DTBKit 的 PresentAnimation（那边叫 DTBBasePresentTransition），
//  只把 SnapKit 换成 NSLayoutConstraint —— 本仓库没有 SnapKit。
//

import UIKit

/// 转场代理。
///
/// 用 `modalPresentationStyle = .custom` + 本代理，而不是 `.overFullScreen`：
/// 后者的 frame 由系统定死、进场动画也不归你管，**转场这一层就没得改了**。
final class PresentTransitioningHandler: NSObject, UIViewControllerTransitioningDelegate {

    private let animation = PresentAnimation()

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        PresentPresentationController(presentedViewController: presented, presenting: presenting)
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

/// 转场控制器：只管**遮罩**。
///
/// 遮罩归转场层而不是业务层，是为了让它跟着转场一起淡入淡出（`transitionCoordinator`），
/// 而不是由业务自己 animate 一个自己的子视图。
final class PresentPresentationController: UIPresentationController {

    /// 压暗被盖住的那一页。不做令牌化 —— 本仓库没有配色令牌体系，
    /// 只有这一处用它，写死比架空一层强。
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

    /// presented view **铺满整屏**，不是只包住卡片。
    ///
    /// 这是这套模式的关键：整屏那块是透明的，上面那截留给"点外面关闭"的遮罩视图，
    /// 下面那截才是卡片。所以进场动画可以简单地平移整个 view —— 视觉上就等于卡片自己滑上来，
    /// 而不需要知道卡片到底多高。
    override var frameOfPresentedViewInContainerView: CGRect {
        containerView?.bounds ?? .zero
    }
}

/// 转场动画：整屏 view 从下往上平移。
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
