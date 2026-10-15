//
//  PlainTextViewController.swift
//  DoSwift
//

import UIKit

/// 一段纯文本的全屏阅读页。
///
/// 从 `UserDefaultsDetailViewController` 提上来的：它当初就只是「把一段字符串铺进
/// `UITextView`」，与 UserDefaults 毫无关系。控制台的「点一行看全文」要的是同一个东西
/// ——一处通用能力，两个工具共用。
///
/// **纯文本**：不解析 JSON、不按类型换控件。要看的本来就是「它到底长什么样」。
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

        // 只读但**可选中**：调试时最常见的下一步就是把它复制走
        textView.isEditable = false
        textView.isSelectable = true

        // 等宽：Data、JSON、日志里的对齐输出，等宽才看得出结构
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
