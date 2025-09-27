//
//  DoSwiftHierarchyHelper.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/27.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// 视图层级辅助工具
public class DoSwiftHierarchyHelper {

    public static let shared = DoSwiftHierarchyHelper()

    private init() {}

    // MARK: - Window Management

    /// 获取所有窗口
    public func getAllWindows() -> [UIWindow] {
        return getAllWindows(ignorePrefix: nil)
    }

    /// 获取所有窗口，可过滤指定前缀
    public func getAllWindows(ignorePrefix prefix: String?) -> [UIWindow] {
        var allWindows: [UIWindow] = []

        // iOS 13+ Scene-based 应用
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    allWindows.append(contentsOf: windowScene.windows)
                }
            }
        } else {
            // iOS 13 之前
            if let windows = UIApplication.shared.windows as [UIWindow]? {
                allWindows = windows
            }
        }

        // 按窗口层级排序
        allWindows.sort { $0.windowLevel.rawValue < $1.windowLevel.rawValue }

        // 过滤指定前缀的窗口
        if let prefix = prefix, !prefix.isEmpty {
            allWindows = allWindows.filter { window in
                !String(describing: type(of: window)).hasPrefix(prefix)
            }
        }

        return allWindows
    }

    // MARK: - View Hierarchy Traversal

    /// 构建视图层级树
    public func buildHierarchyTree() -> [DoSwiftViewNode] {
        let windows = getAllWindows(ignorePrefix: "DoSwift")
        var rootNodes: [DoSwiftViewNode] = []

        for window in windows {
            let windowNode = DoSwiftViewNode(view: window, parent: nil, depth: 0)
            buildViewNode(windowNode)
            rootNodes.append(windowNode)
        }

        return rootNodes
    }

    /// 递归构建视图节点
    private func buildViewNode(_ parentNode: DoSwiftViewNode) {
        guard let parentView = parentNode.view else { return }

        for subview in parentView.subviews {
            let childNode = DoSwiftViewNode(view: subview, parent: parentNode, depth: parentNode.depth + 1)
            parentNode.children.append(childNode)
            buildViewNode(childNode)
        }
    }

    /// 查找指定视图的节点路径
    public func findNodePath(for targetView: UIView, in rootNodes: [DoSwiftViewNode]) -> [DoSwiftViewNode]? {
        for rootNode in rootNodes {
            if let path = findNodePath(for: targetView, in: rootNode, currentPath: []) {
                return path
            }
        }
        return nil
    }

    private func findNodePath(for targetView: UIView, in node: DoSwiftViewNode, currentPath: [DoSwiftViewNode]) -> [DoSwiftViewNode]? {
        let newPath = currentPath + [node]

        if node.view === targetView {
            return newPath
        }

        for child in node.children {
            if let foundPath = findNodePath(for: targetView, in: child, currentPath: newPath) {
                return foundPath
            }
        }

        return nil
    }

    // MARK: - View Highlighting

    /// 高亮显示指定视图
    public func highlightView(_ view: UIView) {
        removeAllHighlights()

        let overlay = createHighlightOverlay(for: view)
        view.superview?.addSubview(overlay)

        // 3秒后自动移除高亮
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            overlay.removeFromSuperview()
        }
    }

    /// 移除所有高亮效果
    public func removeAllHighlights() {
        getAllWindows().forEach { window in
            removeHighlights(from: window)
        }
    }

    private func removeHighlights(from view: UIView) {
        view.subviews.forEach { subview in
            if subview.tag == DoSwiftConstants.highlightViewTag {
                subview.removeFromSuperview()
            } else {
                removeHighlights(from: subview)
            }
        }
    }

    private func createHighlightOverlay(for view: UIView) -> UIView {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        overlay.layer.borderColor = UIColor.systemRed.cgColor
        overlay.layer.borderWidth = 2.0
        overlay.isUserInteractionEnabled = false
        overlay.tag = DoSwiftConstants.highlightViewTag

        return overlay
    }
}

// MARK: - Constants

private enum DoSwiftConstants {
    static let highlightViewTag = 999888777
}