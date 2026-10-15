//
//  BasePresentFitViewController.swift
//  DoSwift
//
//  「底部升起、高度由内容决定」的弹层基类。
//  照搬 DTBKit 的 BasePresentFitViewController，只把 SnapKit 换成 NSLayoutConstraint。
//

import UIKit

/// 弹层容器父类。
///
/// 仿系统，底部向上的 present 效果 —— 但和系统不一样的是：**整体高度由子类相对
/// `contentView` 的自撑约束决定**，所以一个只有一行输入的卡片是矮的，一个十几行列表的
/// 卡片是高的，同一个基类。
///
/// 分工是这套模式最要紧的地方：
///   * **转场层**（`PresentAnimation`）负责遮罩、进场退场
///   * **本类**负责「透明的整屏 + 上半截点击关闭 + 下半截卡片」这个结构
///   * **子类**只负责卡片自己的排版
///
/// 子类把内容放进 `contentView` 即可，不要自己去碰 `view` 的约束。
class BasePresentFitViewController: UIViewController {

    /// 业务容器。透明，**尺寸由子类的约束自撑**，贴住底边。
    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 上半截的透明遮罩：点它关闭。
    lazy var maskTapView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskTapped)))
        return view
    }()

    /// 遮罩点击事件。默认关掉自己；子类可以重写来拦截（比如先弹个确认）。
    lazy var maskTapEventHandler: (() -> Void)? = { [weak self] in
        self?.dismiss(animated: true)
    }
 
    private let transitionHandler = PresentTransitioningHandler()

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

        // 这两对优先级是"高度由内容决定"的机关：
        // 遮罩要能伸能缩（吃掉剩下的空间），容器要贴着内容的尺寸不动。
        maskTapView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        maskTapView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        contentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        contentView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        box.addSubview(maskTapView)
        box.addSubview(contentView)

        maskTapView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 遮罩从顶到底铺到卡片上沿为止 —— 它和卡片的交界就是"卡片的顶边"
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
