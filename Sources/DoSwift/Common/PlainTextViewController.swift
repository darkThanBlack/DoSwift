//
//  PlainTextViewController.swift
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

    final class PlainTextViewController: UIViewController {

        private let text: String

        init(title: String, text: String) {
            self.text = text
            super.init(nibName: nil, bundle: nil)
            self.title = title
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private lazy var textView: UITextView = {
            let textView = UITextView()
            textView.text = text
            textView.backgroundColor = .systemBackground

            textView.isEditable = false
            textView.isSelectable = true

            textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
            textView.alwaysBounceVertical = true
            return textView
        }()

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .systemBackground
            view.addSubview(textView)

            textView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: view.topAnchor),
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }
}
