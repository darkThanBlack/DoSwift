//
//  HierarchyInspectorOverlayView.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/29.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol HierarchyInspectorOverlayViewDelegate: AnyObject {
    func overlayViewDidRequestClose(_ overlayView: HierarchyInspectorOverlayView)
    func overlayViewDidRequestMoreInfo(_ overlayView: HierarchyInspectorOverlayView)
    func overlayViewDidRequestParentViews(_ overlayView: HierarchyInspectorOverlayView)
    func overlayViewDidRequestSubviews(_ overlayView: HierarchyInspectorOverlayView)
}

/// UI 结构检查器的完整覆盖层视图 - 纯 UI 展示
class HierarchyInspectorOverlayView: UIView {

    // MARK: - Properties

    weak var delegate: HierarchyInspectorOverlayViewDelegate?
    weak var targetWindow: UIWindow?
    weak var driftView: DriftView?

    private var selectedView: UIView?
    private var currentDragLocation: CGPoint = .zero

    // MARK: - UI Elements

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

    // 属性检查器浮窗
    private let inspectorView: HierarchyInspectorView = {
        let view = HierarchyInspectorView()
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // 添加所有子视图
        [xAxisLine, yAxisLine, highlightView, inspectorView].forEach {
            addSubview($0)
        }

        // 设置检查器代理
        inspectorView.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else { return }

        // 设置 DriftView 初始位置（如果还没设置）
        setupDriftViewFrameIfNeeded()

        // 属性检查器 - 底部固定高度
        let inspectorHeight: CGFloat = 200
        inspectorView.frame = CGRect(
            x: 0,
            y: bounds.height - inspectorHeight,
            width: bounds.width,
            height: inspectorHeight
        )
    }

    private func setupDriftViewFrameIfNeeded() {
        guard let driftView = driftView, driftView.frame == .zero else { return }

        let buttonSize: CGFloat = 40
        let buttonMargin: CGFloat = 20
        let topSafeArea = safeAreaInsets.top

        // 从 UserDefaults 恢复位置
        let savedFrame: [String: CGFloat]? = UserDefaults.standard.object(forKey: UserDefaults.driftFrameKey) as? [String: CGFloat]

        let defaultX = bounds.width - buttonSize - buttonMargin
        let defaultY = topSafeArea + 100

        driftView.frame = CGRect(
            x: savedFrame?["x"] ?? defaultX,
            y: savedFrame?["y"] ?? defaultY,
            width: buttonSize,
            height: buttonSize
        )

        // 添加 DriftView 到覆盖层
        addSubview(driftView)
    }

    // MARK: - Public Methods

    func configure(targetWindow: UIWindow, driftView: DriftView) {
        self.targetWindow = targetWindow
        self.driftView = driftView
    }

    func updateSelectedView(_ view: UIView) {
        selectedView = view
        inspectorView.updateSelectedView(view)
    }

    func highlightView(_ view: UIView) {
        guard let appWindow = DoSwiftCore.shared.appWindow,
              let superview = view.superview else { return }

        // 计算在主应用窗口中的位置
        let frameInWindow = superview.convert(view.frame, to: appWindow)

        // 由于覆盖层就在主应用窗口中，直接使用窗口坐标
        highlightView.frame = frameInWindow
        highlightView.isHidden = false

        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideHighlight()
        }
    }

    func hideHighlight() {
        highlightView.isHidden = true
    }

    func showInspector() {
        inspectorView.isHidden = false
    }

    func hideInspector() {
        inspectorView.isHidden = true
        hideDragIndicators()
        hideHighlight()
    }

    func toggleInspector() {
        if inspectorView.isHidden {
            showInspector()
        } else {
            hideInspector()
        }
    }

    // MARK: - Drag Handling

    func updateDragLocation(_ location: CGPoint) {
        currentDragLocation = location
        showAxisLines(at: location)
        inspectorView.updateDragLocation(location)
    }

    func hideDragIndicators() {
        hideAxisLines()
    }

    private func showAxisLines(at location: CGPoint) {
        // 显示 X 轴线 (水平)
        xAxisLine.frame = CGRect(x: 0, y: location.y, width: bounds.width, height: 1)
        xAxisLine.isHidden = false

        // 显示 Y 轴线 (垂直)
        yAxisLine.frame = CGRect(x: location.x, y: 0, width: 1, height: bounds.height)
        yAxisLine.isHidden = false
    }

    private func hideAxisLines() {
        xAxisLine.isHidden = true
        yAxisLine.isHidden = true
    }
}

// MARK: - HierarchyInspectorViewDelegate

extension HierarchyInspectorOverlayView: HierarchyInspectorViewDelegate {
    func inspectorViewDidRequestClose(_ inspectorView: HierarchyInspectorView) {
        delegate?.overlayViewDidRequestClose(self)
    }

    func inspectorViewDidRequestMoreInfo(_ inspectorView: HierarchyInspectorView) {
        delegate?.overlayViewDidRequestMoreInfo(self)
    }

    func inspectorViewDidRequestParentViews(_ inspectorView: HierarchyInspectorView) {
        delegate?.overlayViewDidRequestParentViews(self)
    }

    func inspectorViewDidRequestSubviews(_ inspectorView: HierarchyInspectorView) {
        delegate?.overlayViewDidRequestSubviews(self)
    }
}