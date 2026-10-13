//
//  UserDefaultsDetailViewController.swift
//  DoSwift
//

import UIKit

/// 一条 UserDefaults 的完整值。
///
/// **纯文本**：把 `String(describing:)` 的结果原样铺进一个原生 `UITextView`。
/// 不解析 Data / JSON，也不按类型换控件——要看的就是「这里面到底存了什么」。
final class UserDefaultsDetailViewController: UIViewController {

    private let text: String

    init(key: String, text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        title = key
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.text = text
        textView.backgroundColor = .systemBackground

        // 只读但**可选中**：调试时最常见的下一步就是把它复制走
        textView.isEditable = false
        textView.isSelectable = true

        // 等宽：Data、JSON 这类值对齐了才看得出结构
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
