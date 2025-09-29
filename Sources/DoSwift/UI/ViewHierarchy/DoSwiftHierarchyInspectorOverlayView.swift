//
//  DoSwiftHierarchyInspectorOverlayView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// UI 结构检查器的完整覆盖层视图
class DoSwiftHierarchyInspectorOverlayView: UIView, UIGestureRecognizerDelegate {

    // MARK: - Properties

    weak var targetWindow: UIWindow?
    weak var selectedView: UIView?

    var onClose: (() -> Void)?

    // MARK: - UI Elements

    // 浮窗按钮 (类似 AssistiveTouch)
    private let floatingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        button.setTitle("🎯", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        return button
    }()

    // X 轴辅助线
    private let xAxisLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.7)
        view.isHidden = true
        return view
    }()

    // Y 轴辅助线
    private let yAxisLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.7)
        view.isHidden = true
        return view
    }()

    // 坐标标签
    private let coordinateLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    // 属性检查器浮窗
    private let inspectorView: DoSwiftHierarchyInspectorView = {
        let view = DoSwiftHierarchyInspectorView()
        view.isHidden = true
        return view
    }()

    // 高亮边框
    private let highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.systemRed.cgColor
        view.layer.borderWidth = 2.0
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // 添加所有子视图
        [xAxisLine, yAxisLine, coordinateLabel, highlightView, floatingButton, inspectorView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // 浮窗按钮约束
        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60),
            floatingButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            floatingButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 100)
        ])

        // 属性检查器约束
        NSLayoutConstraint.activate([
            inspectorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            inspectorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            inspectorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            inspectorView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // 设置按钮事件
        floatingButton.addTarget(self, action: #selector(floatingButtonTapped), for: .touchUpInside)

        // 设置检查器回调
        setupInspectorCallbacks()
    }

    private func setupGestures() {
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGesture)

        // 添加拖拽手势用于显示辅助线
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)

        // 设置手势同时识别
        tapGesture.delegate = self
        panGesture.delegate = self

        // 允许点击手势与拖拽手势同时存在
        tapGesture.require(toFail: panGesture)
    }

    private func setupInspectorCallbacks() {
        inspectorView.onParentViewsTapped = { [weak self] in
            self?.showParentViews()
        }
        inspectorView.onSubviewsTapped = { [weak self] in
            self?.showSubviews()
        }
        inspectorView.onMoreInfoTapped = { [weak self] in
            self?.showMoreInfo()
        }
    }

    // MARK: - Gesture Handling

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)

        // 如果点击在浮窗按钮或检查器上，不处理
        if floatingButton.frame.contains(location) ||
           (inspectorView.isHidden == false && inspectorView.frame.contains(location)) {
            return
        }

        // 查找点击位置的视图
        if let hitView = findViewAtLocation(location) {
            selectView(hitView)
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began, .changed:
            showAxisLines(at: location)
        case .ended, .cancelled:
            hideAxisLines()
        default:
            break
        }
    }

    @objc private func floatingButtonTapped() {
        // 切换检查器显示状态
        inspectorView.isHidden.toggle()

        if inspectorView.isHidden {
            hideAxisLines()
            hideHighlight()
        }
    }

    // MARK: - View Finding

    private func findViewAtLocation(_ location: CGPoint) -> UIView? {
        guard let targetWindow = targetWindow else { return nil }

        // 转换坐标到目标窗口
        let locationInWindow = targetWindow.convert(location, from: self)

        // 递归查找最深层的视图
        return findDeepestViewAtLocation(locationInWindow, in: targetWindow)
    }

    private func findDeepestViewAtLocation(_ location: CGPoint, in view: UIView) -> UIView? {
        // 跳过 DoSwift 相关的视图
        if String(describing: type(of: view)).contains("DoSwift") {
            return nil
        }

        // 检查点击是否在当前视图范围内
        let localPoint = view.convert(location, from: targetWindow)
        if !view.bounds.contains(localPoint) {
            return nil
        }

        // 递归检查子视图
        for subview in view.subviews.reversed() {
            if let deeperView = findDeepestViewAtLocation(location, in: subview) {
                return deeperView
            }
        }

        return view
    }

    // MARK: - View Selection

    private func selectView(_ view: UIView) {
        selectedView = view
        inspectorView.selectedView = view
        highlightView(view)

        if inspectorView.isHidden {
            inspectorView.isHidden = false
        }
    }

    private func highlightView(_ view: UIView) {
        guard let targetWindow = targetWindow,
              let superview = view.superview else { return }

        // 计算在目标窗口中的位置
        let frameInWindow = superview.convert(view.frame, to: targetWindow)

        // 由于覆盖层就在目标窗口中，直接使用窗口坐标
        highlightView.frame = frameInWindow
        highlightView.isHidden = false

        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideHighlight()
        }
    }

    private func hideHighlight() {
        highlightView.isHidden = true
    }

    // MARK: - Axis Lines

    private func showAxisLines(at location: CGPoint) {
        // 显示 X 轴线 (水平)
        xAxisLine.frame = CGRect(x: 0, y: location.y, width: bounds.width, height: 1)
        xAxisLine.isHidden = false

        // 显示 Y 轴线 (垂直)
        yAxisLine.frame = CGRect(x: location.x, y: 0, width: 1, height: bounds.height)
        yAxisLine.isHidden = false

        // 显示坐标标签
        let coordinateText = String(format: "(%.0f, %.0f)", location.x, location.y)
        coordinateLabel.text = coordinateText
        coordinateLabel.sizeToFit()
        coordinateLabel.frame = CGRect(
            x: location.x + 10,
            y: location.y - 20,
            width: coordinateLabel.bounds.width + 8,
            height: coordinateLabel.bounds.height + 4
        )
        coordinateLabel.isHidden = false
    }

    private func hideAxisLines() {
        xAxisLine.isHidden = true
        yAxisLine.isHidden = true
        coordinateLabel.isHidden = true
    }

    // MARK: - Inspector Actions

    private func showParentViews() {
        guard let selectedView = selectedView else { return }

        let alert = UIAlertController(title: "父视图", message: nil, preferredStyle: .actionSheet)

        var currentView: UIView? = selectedView.superview
        var level = 1

        while let parentView = currentView {
            let title = "Level \(level): \(String(describing: type(of: parentView)))"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectView(parentView)
            })

            currentView = parentView.superview
            level += 1

            if level > 10 { break }
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        // 从目标窗口的根控制器弹出
        if let rootViewController = targetWindow?.rootViewController {
            var presentingVC = rootViewController
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        }
    }

    private func showSubviews() {
        guard let selectedView = selectedView else { return }

        let subviews = selectedView.subviews.filter { !String(describing: type(of: $0)).contains("DoSwift") }

        if subviews.isEmpty {
            let alert = UIAlertController(title: "子视图", message: "该视图没有子视图", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))

            if let rootViewController = targetWindow?.rootViewController {
                var presentingVC = rootViewController
                while let presented = presentingVC.presentedViewController {
                    presentingVC = presented
                }
                presentingVC.present(alert, animated: true)
            }
            return
        }

        let alert = UIAlertController(title: "子视图", message: nil, preferredStyle: .actionSheet)

        for (index, subview) in subviews.enumerated() {
            let title = "\(index + 1): \(String(describing: type(of: subview)))"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectView(subview)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let rootViewController = targetWindow?.rootViewController {
            var presentingVC = rootViewController
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        }
    }

    private func showMoreInfo() {
        // 关闭当前检查器并跳转到详细页面
        onClose?()
    }

    // MARK: - Public Methods

    func configure(targetWindow: UIWindow) {
        self.targetWindow = targetWindow
    }

    func showInspector() {
        inspectorView.isHidden = false
    }

    func hideInspector() {
        inspectorView.isHidden = true
        hideAxisLines()
        hideHighlight()
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}