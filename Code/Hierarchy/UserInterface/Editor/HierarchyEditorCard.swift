//
//  HierarchyEditorCard.swift
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

    @objc(DOAlertTransitioningHandler)
    final class AlertTransitioningHandler: NSObject, UIViewControllerTransitioningDelegate {

        private let animation = DO.AlertAnimation()

        func presentationController(forPresented presented: UIViewController,
                                    presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            DO.AlertPresentationController(presentedViewController: presented, presenting: presenting)
        }

        func animationController(forPresented presented: UIViewController,
                                 presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            animation.to(.centerShow)
        }

        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            animation.to(.centerHide)
        }
    }

    @objc(DOAlertPresentationController)
    final class AlertPresentationController: UIPresentationController {

        private lazy var scrimView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            v.alpha = 0
            v.isUserInteractionEnabled = false
            return v
        }()

        override func presentationTransitionWillBegin() {
            guard let containerView else { return }
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

    @objc(DOAlertAnimation)
    final class AlertAnimation: NSObject, UIViewControllerAnimatedTransitioning {

        enum Kind { case centerShow, centerHide }
        private var kind: Kind?

        func to(_ kind: Kind) -> Self { self.kind = kind; return self }

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.3 }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let container = transitionContext.containerView

            guard let k = kind else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }

            switch k {
            case .centerShow:
                guard let toView = transitionContext.view(forKey: .to) else {
                    transitionContext.completeTransition(false); return
                }
                container.addSubview(toView)
                toView.frame = container.bounds
                toView.alpha = 0
                toView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                    toView.alpha = 1; toView.transform = .identity
                }) { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled && finished)
                }

            case .centerHide:
                guard let fromView = transitionContext.view(forKey: .from) else {
                    transitionContext.completeTransition(false); return
                }
                fromView.alpha = 1; fromView.transform = .identity
                UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                    fromView.alpha = 0; fromView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                }) { finished in
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled && finished)
                }
            }
        }
    }

    @objc(DOBaseAlertViewController)
    class BaseAlertViewController: UIViewController {

        lazy var contentView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            return v
        }()

        lazy var maskTapView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            let tap = UITapGestureRecognizer(target: self, action: #selector(maskTapped))
            v.addGestureRecognizer(tap)
            return v
        }()

        lazy var maskTapEventHandler: (() -> Void)? = { [weak self] in self?.dismiss(animated: true) }

        private let transitionHandler = DO.AlertTransitioningHandler()

        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .custom
            transitioningDelegate = transitionHandler
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override open func viewDidLoad() {
            super.viewDidLoad()
            loadSubviews(in: view)
        }

        private func loadSubviews(in box: UIView) {
            box.backgroundColor = .clear
            box.addSubview(maskTapView)
            box.addSubview(contentView)
            maskTapView.translatesAutoresizingMaskIntoConstraints = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                maskTapView.topAnchor.constraint(equalTo: box.topAnchor),
                maskTapView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                maskTapView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                maskTapView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
                contentView.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            ])
        }

        @objc private func maskTapped() { maskTapEventHandler?() }
    }

    @objc(DOHierarchyEditorCard)
    final class HierarchyEditorCard: DO.BaseAlertViewController {

        private let key: String
        private let kind: DO.ValueKind
        private let input: DO.HierarchyValueInput
        private let currentText: String
        private let onCommit: (DO.ValueKind) -> Void

        private var isValid = true

        private var shouldShowCurrentValue: Bool {
            if case .text = kind { return false }
            return true
        }

        init(key: String, kind: DO.ValueKind, input: DO.HierarchyValueInput, onCommit: @escaping (DO.ValueKind) -> Void) {
            self.key = key
            self.kind = kind
            self.input = input
            self.currentText = DO.HierarchyPropertyEngine.shared.displayText(of: kind)
            self.onCommit = onCommit
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()

            maskTapEventHandler = { [weak self] in self?.dismiss(animated: true) }

            setupCard()

            input.onValidityChange = { [weak self] isValid in self?.setValid(isValid) }
            setValid(input.readValue() != nil)
        }

        private lazy var cardView: UIView = {
            let view = UIView()
            view.backgroundColor = .systemBackground
            view.layer.cornerRadius = 16
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.18
            view.layer.shadowRadius = 22
            view.layer.shadowOffset = CGSize(width: 0, height: 8)
            return view
        }()

        private lazy var clipper: UIView = {
            let view = UIView()
            view.backgroundColor = .systemBackground
            view.layer.cornerRadius = 16
            view.layer.masksToBounds = true
            return view
        }()

        private lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.alwaysBounceVertical = false
            view.keyboardDismissMode = .interactive
            return view
        }()

        private lazy var doneButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle(DO.Text.Hierarchy.done, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.tertiaryLabel, for: .disabled)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 9
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.addTarget(self, action: #selector(commit), for: .touchUpInside)
            return button
        }()

        private func setupCard() {
            cardView.addSubview(clipper)
            contentView.addSubview(cardView)

            cardView.translatesAutoresizingMaskIntoConstraints = false
            clipper.translatesAutoresizingMaskIntoConstraints = false

            let cardWidth = DO.Core.screenBounds.width - 32
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
                cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

                cardView.widthAnchor.constraint(equalToConstant: cardWidth),
                cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                              constant: 16),
                cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                 constant: -16),
            ])

            Pinning.pin(clipper, to: cardView)
            buildCardContents()
        }

        private func buildCardContents() {
            let titleLabel = UILabel()
            titleLabel.text = key
            titleLabel.font = .monospacedSystemFont(ofSize: 17, weight: .semibold)
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.7
            titleLabel.numberOfLines = 1

            let grabber = UIView()
            grabber.backgroundColor = .tertiaryLabel
            grabber.layer.cornerRadius = 2.5

            let showCurrent = shouldShowCurrentValue
            let currentLabel = UILabel()
            currentLabel.text = currentText
            currentLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            currentLabel.textColor = .secondaryLabel
            currentLabel.numberOfLines = 2
            currentLabel.lineBreakMode = .byTruncatingMiddle
            currentLabel.isHidden = !showCurrent

            let titleStack = UIStackView(arrangedSubviews: [titleLabel, currentLabel])
            titleStack.axis = .vertical
            titleStack.alignment = .fill
            titleStack.spacing = 3

            let header = UIView()
            [grabber, titleStack].forEach(header.addSubview)
            header.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))

            let bottomBar = UIView()
            bottomBar.addSubview(doneButton)

            let content = UIView()
            content.addSubview(input)
            scrollView.addSubview(content)

            let stack = UIStackView(arrangedSubviews: [header, divider(), scrollView, divider(), bottomBar])
            stack.axis = .vertical
            stack.spacing = 0
            clipper.addSubview(stack)

            [stack, header, content, titleStack, titleLabel, currentLabel, grabber, bottomBar, doneButton, input].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            Pinning.pin(stack, to: clipper)

            NSLayoutConstraint.activate([
                // header
                grabber.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
                grabber.centerXAnchor.constraint(equalTo: header.centerXAnchor),
                grabber.widthAnchor.constraint(equalToConstant: 36),
                grabber.heightAnchor.constraint(equalToConstant: 5),

                titleStack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
                titleStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: DO.HierarchyEditorStyle.padding),
                titleStack.trailingAnchor.constraint(equalTo: header.trailingAnchor,
                                                     constant: -DO.HierarchyEditorStyle.padding),
                titleStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16),

                // bottomBar
                doneButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 10),
                doneButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -10),
                doneButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor,
                                                     constant: -DO.HierarchyEditorStyle.padding),

                content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            ])

            Pinning.pin(content, to: scrollView.contentLayoutGuide)
            Pinning.pin(input, to: content, insets: UIEdgeInsets(top: DO.HierarchyEditorStyle.padding,
                                                                 left: DO.HierarchyEditorStyle.padding,
                                                                 bottom: DO.HierarchyEditorStyle.padding,
                                                                 right: DO.HierarchyEditorStyle.padding))

            let hugContent = scrollView.heightAnchor.constraint(equalTo: content.heightAnchor)
            hugContent.priority = UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue - 1)
            hugContent.isActive = true
        }

        private func divider() -> UIView {
            let line = UIView()
            line.backgroundColor = .separator
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
            return line
        }

        private func setValid(_ isValid: Bool) {
            self.isValid = isValid
            doneButton.isEnabled = isValid
            doneButton.backgroundColor = isValid ? .systemBlue : .tertiarySystemFill
            doneButton.setTitleColor(isValid ? .white : .tertiaryLabel, for: .normal)
        }

        @objc private func commit() {
            guard isValid, let value = input.readValue() else { return }
            view.endEditing(true)
            onCommit(value)
            dismiss(animated: true)
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let offset = max(0, gesture.translation(in: view).y)

            switch gesture.state {
            case .changed:
                cardView.transform = CGAffineTransform(translationX: 0, y: offset)

            case .ended, .cancelled:
                if offset > 90 || gesture.velocity(in: view).y > 600 {
                    view.endEditing(true)
                    dismiss(animated: true)
                } else {
                    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                        self.cardView.transform = .identity
                    }
                }

            default:
                break
            }
        }
    }

}

/// File-local layout helpers. Deliberately not a `UIView` extension: the library adds no
/// members to UIKit types.
private enum Pinning {

    static func pin(_ view: UIView, to other: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            view.leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            view.bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom),
        ])
    }

    static func pin(_ view: UIView, to guide: UILayoutGuide, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            view.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
