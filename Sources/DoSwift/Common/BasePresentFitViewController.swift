//
//  BasePresentFitViewController.swift
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

    class BasePresentFitViewController: UIViewController {

        lazy var contentView: UIView = {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }()

        lazy var maskTapView: UIView = {
            let view = UIView()
            view.backgroundColor = .clear
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskTapped)))
            return view
        }()

        lazy var maskTapEventHandler: (() -> Void)? = { [weak self] in
            self?.dismiss(animated: true)
        }

        private let transitionHandler = DO.PresentTransitioningHandler()

        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            modalPresentationStyle = .custom
            transitioningDelegate = transitionHandler
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            loadSubviews(in: view)
        }

        private func loadSubviews(in box: UIView) {
            box.backgroundColor = .clear

            maskTapView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
            maskTapView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
            contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            contentView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

            box.addSubview(maskTapView)
            box.addSubview(contentView)

            maskTapView.translatesAutoresizingMaskIntoConstraints = false
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                maskTapView.topAnchor.constraint(equalTo: box.topAnchor),
                maskTapView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                maskTapView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                maskTapView.bottomAnchor.constraint(equalTo: contentView.topAnchor),

                contentView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            ])
        }

        @objc private func maskTapped() {
            maskTapEventHandler?()
        }
    }
}
