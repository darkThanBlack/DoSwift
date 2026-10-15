//
//  HierarchyEditorCard.swift
//  DoSwift
//
//  属性编辑卡片的**外壳**：标题行、滚动输入区、底栏。全部类型共用。
//
//  使用 **alert 风格转场**（中心缩放），仿 DTBKit 的 `AlertAnimation` + `BaseAlertViewController`。
//  - 居中缩放动画、scrim、点击空白关闭，全在转场层里
//  - cardView 自身居中，宽高由这里的约束决定
//  - 点击空白关闭由 `maskTapEventHandler` 兜底（默认 dismiss）
//
// 这里只做两件事：把卡片放进 `contentView`，以及卡片自己内部的排版。
//
// 容器四条规则：
//
//   * **浮着，不是另一页**：四周留白 16、四角全圆、带阴影。这张卡片属于"刚才点的那一行"，
//     边缘贴到屏幕上就会像换了一页。
//   * **高度随内容长，封顶在安全区之内**。一个 `tag` 就是一张矮卡片；
//     13 项的 `UIViewContentMode` 长到贴顶之后，多出来的部分由输入区自己滚。
//   * **标题行钉住，只有输入区滚动** —— 卡片里没有底栏。
//   * **键盘弹起时卡片不再需要上移**，因为 alert 居中，键盘大概率遮不住；
//     极端情况（横屏/巨大键盘）由 `UITextView` 自己滚动处理。
//
// **底栏**：完成按钮做成底部长条；标题栏右侧放关闭按钮
// 点击空白关闭由 `maskTapEventHandler` 兜底（默认 dismiss）。
import UIKit

// MARK: - Alert Transition (仿 DTBKit)

/// alert 转场代理：固定居中缩放动画。
final class AlertTransitioningHandler: NSObject, UIViewControllerTransitioningDelegate {

    private let animation = AlertAnimation()

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        AlertPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animation.to(.centerShow)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animation.to(.centerHide)
    }
}

/// alert 转场控制器：负责视觉 scrim 的淡入淡出。
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

    /// presented view **铺满整屏**，上面由 scrim、下面由卡片自己决定位置
    override var frameOfPresentedViewInContainerView: CGRect {
        containerView?.bounds ?? .zero
    }
}

/// alert 转场动画：仅 centerShow / centerHide，仿系统 alert 缩放淡入淡出。
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

// MARK: - Base Alert View Controller (仿 DTBKit)

/// alert 转场容器父类。
///
/// - 仿系统，居中的缩放弹出效果
/// - card 叠加在 scrim 上层并中心对齐，宽高由子类控制
/// - 灰色背景由转场层提供
/// - 点击空白关闭由 `maskTapEventHandler` 兜底（默认 dismiss）
open class BaseAlertViewController: UIViewController {

    /// 业务容器（透明，中心对齐；宽高由子类约束）
    public lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 透明遮罩（铺满，卡片叠加其上）
    public lazy var maskTapView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(maskTapped))
        v.addGestureRecognizer(tap)
        return v
    }()

    /// 遮罩点击事件。默认 dismiss；子类可重写拦截
    public lazy var maskTapEventHandler: (() -> Void)? = { [weak self] in self?.dismiss(animated: true) }

    private let transitionHandler = AlertTransitioningHandler()

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionHandler
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

// MARK: - Editor Card

/// 属性编辑卡片的**外壳**：标题行、滚动输入区、底栏。全部类型共用。
///
/// 使用 **alert 风格转场**（中心缩放），仿 DTBKit 的 `AlertAnimation` + `BaseAlertViewController`。
/// - 居中缩放动画、scrim、点击空白关闭，全在转场层里
/// - cardView 自身居中，宽高由这里的约束决定
/// - 点击空白关闭由 `maskTapEventHandler` 兜底（默认 dismiss）
///
/// 这里只做两件事：把卡片放进 `contentView`，以及卡片自己内部的排版。
///
/// 容器四条规则：
///
///   * **浮着，不是另一页**：四周留白 16、四角全圆、带阴影。
///   * **高度完全由内容决定**，封顶在安全区之内。一个 `tag` 就是一张矮卡片；
///     13 项的 `UIViewContentMode` 长到封顶之后，多出来的部分由外层滚动视图滚。
///   * **标题行钉住，只有输入区滚动**。
///   * **键盘弹起时卡片不上移**：alert 居中，键盘大概率遮不住；极端情况由输入区自己滚。
///
/// **动作只有一个**：底栏右下角的「完成」。关闭走"点卡片外面"和"下拉"——
/// 那两条路容器已经提供，再给一个关闭按钮是三套说法。
final class HierarchyEditorCard: BaseAlertViewController {

    private let key: String
    private let kind: ValueKind
    private let input: HierarchyValueInput
    private let currentText: String
    private let onCommit: (ValueKind) -> Void

    private var isValid = true

    /// 哪些类型不展示副标题：只有 `text` —— 编辑框里就是值本身，再说一遍是废话。
    /// 其余类型（几何 / 颜色 / 字体…）副标题展示**值本身**，不加"当前"二字。
    private var shouldShowCurrentValue: Bool {
        if case .text = kind { return false }
        return true
    }

    /// - Parameters:
    ///   - kind: 用来判断类型，决定卡片高度与是否展示副标题
    ///   - input: 中间那块。由 `HierarchyValueInputFactory` 按类型造好交进来。
    init(key: String, kind: ValueKind, input: HierarchyValueInput, onCommit: @escaping (ValueKind) -> Void) {
        self.key = key
        self.kind = kind
        self.input = input
        self.currentText = HierarchyPropertyEngine.shared.displayText(of: kind)
        self.onCommit = onCommit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 点卡片外面关闭。默认行为就是 dismiss，这里显式写一遍是给"能被重写"留个位置
        maskTapEventHandler = { [weak self] in self?.dismiss(animated: true) }

        setupCard()

        input.onValidityChange = { [weak self] isValid in self?.setValid(isValid) }
        setValid(input.readValue() != nil)
    }

    // MARK: - Views

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

    /// 裁切层。`masksToBounds` 会把阴影一起裁掉，所以阴影和裁切必须分两层。
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

    /// 卡片上唯一的动作按钮。底栏右下角，普通尺寸
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("完成", for: .normal)
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

        // contentView **没有自己的尺寸**（基类只给了 centerX / centerY），
        // 所以这里必须把卡片贴满它的四条边，让它撑出尺寸。
        //
        // 漏掉这一步的症状很有欺骗性：卡片**照样画得出来**（`clipsToBounds` 为 false，
        // subview 可以画到父视图边界之外），但 `contentView` 实际是 0×0 ——
        // 而 0×0 的视图命不中任何点，于是点击全部落到下面铺满全屏的 `maskTapView` 上，
        // 表现为「卡片显示正常，但点哪儿都关闭」。
        let cardWidth = UIScreen.main.bounds.width - 32
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            cardView.widthAnchor.constraint(equalToConstant: cardWidth),
            // 高度封顶在安全区之内。不写成「≤ 安全区高度」是因为 `contentView` 居中于**整屏**，
            // 而安全区上下并不对称（状态栏与 home 指示条高度不同），只按总高封顶会有几 px
            // 探进安全区。两条不等式夹住，内容更长时由输入区自己滚。
            cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 16),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                             constant: -16),
        ])

        clipper.pinEdges(to: cardView)
        buildCardContents()
    }

    private func buildCardContents() {
        let titleLabel = UILabel()
        titleLabel.text = key
        titleLabel.font = .monospacedSystemFont(ofSize: 17, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.numberOfLines = 1

        // 抓手。它不只是装饰 —— 标题行是**唯一**挂了拖拽手势的地方，这条横杠就是告诉人"这里能拉"
        let grabber = UIView()
        grabber.backgroundColor = .tertiaryLabel
        grabber.layer.cornerRadius = 2.5

        // 副标题 = 值本身，不拼"当前"。底栏只有一条横杠宽，长值会被截半截；
        // 标题下面有整幅宽度，容得下两行。
        let showCurrent = shouldShowCurrentValue
        let currentLabel = UILabel()
        currentLabel.text = currentText
        currentLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        currentLabel.textColor = .secondaryLabel
        currentLabel.numberOfLines = 2
        currentLabel.lineBreakMode = .byTruncatingMiddle
        currentLabel.isHidden = !showCurrent

        // 标题 + 副标题竖排。**用 stack 而不是「谁底边挂 header 底」那套互斥约束**：
        // stack 会把 `isHidden` 的 arranged subview 移出布局，副标题不显示时标题行自动收窄，
        // 一行条件判断就够了。互斥约束那种写法一旦两条同时 active（把两个都塞进
        // `NSLayoutConstraint.activate` 就会），就会被夹成负高度，副标题直接消失。
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, currentLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .fill
        titleStack.spacing = 3

        // 标题行兼作拖拽把手。**只有它挂 pan**：卡片里全是滚动视图和文本输入，
        // 把 pan 挂在整张卡片上会和它们抢手势 —— 想滚枚举列表，结果把卡片拉下去了。
        let header = UIView()
        [grabber, titleStack].forEach(header.addSubview)
        header.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))

        // 底栏：完成按钮靠右下角，普通尺寸
        let bottomBar = UIView()
        bottomBar.addSubview(doneButton)

        // 滚动视图的内容视图。**先挂上再连约束** ——
        // 少了这一句，`content.widthAnchor == scrollView.frameLayoutGuide.widthAnchor`
        // 就是两个没有共同祖先的东西连在一起，激活时直接抛异常
        let content = UIView()
        content.addSubview(input)
        scrollView.addSubview(content)

        // 底栏上面也来一条分隔线，跟标题行下面那条对称
        let stack = UIStackView(arrangedSubviews: [header, divider(), scrollView, divider(), bottomBar])
        stack.axis = .vertical
        stack.spacing = 0
        clipper.addSubview(stack)

        [stack, header, content, titleStack, titleLabel, currentLabel, grabber, bottomBar, doneButton, input].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        stack.pinEdges(to: clipper)

        NSLayoutConstraint.activate([
            // header
            grabber.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            titleStack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
            titleStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: HierarchyEditorStyle.padding),
            titleStack.trailingAnchor.constraint(equalTo: header.trailingAnchor,
                                                 constant: -HierarchyEditorStyle.padding),
            titleStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16),

            // bottomBar
            doneButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 10),
            doneButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -10),
            doneButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor,
                                                 constant: -HierarchyEditorStyle.padding),

            // 内容按 **contentLayoutGuide** 定位（不是滚动视图自己的边）：那才是"可滚动区域"，
            // 宽度再单独跟 frameLayoutGuide 对齐，于是纵向能滚、横向不滚
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        // `pinEdges` 自己就 activate，不能混在上面的数组里 —— 那会变成 `[Any]`
        content.pinEdges(to: scrollView.contentLayoutGuide)
        input.pinEdges(to: content, insets: UIEdgeInsets(top: HierarchyEditorStyle.padding,
                                                         left: HierarchyEditorStyle.padding,
                                                         bottom: HierarchyEditorStyle.padding,
                                                         right: HierarchyEditorStyle.padding))

        // 卡片高度**跟内容走**：滚动视图想要多高就多高，除非被那条封顶按住。
        // 这一条给 749 —— 比封顶低一级，所以内容长的时候封顶赢、滚动视图比内容矮，
        // 于是内容自己滚。
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

    // MARK: - State

    /// 输入不合法时「完成」置灰。校验由输入区自己判，这里只管把结论用出来。
    private func setValid(_ isValid: Bool) {
        self.isValid = isValid
        doneButton.isEnabled = isValid
        doneButton.backgroundColor = isValid ? .systemBlue : .tertiarySystemFill
        doneButton.setTitleColor(isValid ? .white : .tertiaryLabel, for: .normal)
    }

    // MARK: - Actions

    @objc private func commit() {
        guard isValid, let value = input.readValue() else { return }
        view.endEditing(true)
        onCommit(value)
        dismiss(animated: true)
    }

    // MARK: - Drag

    /// 拉下去就关。和点卡片外面是同一个意思。
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let offset = max(0, gesture.translation(in: view).y)

        switch gesture.state {
        case .changed:
            cardView.transform = CGAffineTransform(translationX: 0, y: offset)

        case .ended, .cancelled:
            // 阈值按**手指走的路**而不是卡片高度算：卡片高度随内容变，
            // 按比例算的话矮卡片要拉到底才认，手感很木
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

// MARK: - UIView Helper

private extension UIView {

    /// 贴满。四处约束长得一样，写四遍只会让上面的排版意图更难读。
    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom),
        ])
    }

    /// 同上，但贴的是 `UILayoutGuide` —— 滚动视图的 contentLayoutGuide 只能这么贴，
    /// 它没有 `UIView` 那一套锚点。
    func pinEdges(to guide: UILayoutGuide, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
