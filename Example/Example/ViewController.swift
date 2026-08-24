import UIKit
import DoSwift

class ViewController: UIViewController {

    private lazy var buttonStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "DoSwift"

        view.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonStack.widthAnchor.constraint(equalToConstant: 220),
        ])

        addButton("Toggle DoSwift", #selector(toggleDoSwift))
        addButton("UI Hierarchy", #selector(launchHierarchy))
    }

    private func addButton(_ title: String, _ action: Selector) {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
        buttonStack.addArrangedSubview(btn)
    }

    @objc private func toggleDoSwift() {
        if DoSwiftCore.shared.window?.isHidden != false {
            DoSwiftCore.shared.start()
        } else {
            DoSwiftCore.shared.stop()
        }
    }

    @objc private func launchHierarchy() {
        // 注入业务主 window 到全局上下文（Hierarchy 拾取以此为基准）
        DoSwiftContext.shared.setup(view.window)
        HierarchyPlugin().pluginDidLoad()
    }
}