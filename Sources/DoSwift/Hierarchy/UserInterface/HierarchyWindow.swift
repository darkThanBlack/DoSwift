//
//  HierarchyWindow.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyWindow.m / .h
//

import UIKit

/// Hierarchy 专用 UIWindow
class HierarchyWindow: UIWindow {

    override init(frame: CGRect) {
        super.init(frame: frame)

        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   windowScene.activationState == .foregroundActive {
                    self.windowScene = windowScene
                    break
                }
            }
        }
        
        windowLevel = .alert - 1

        if rootViewController == nil {
            rootViewController = HierarchyViewController()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func showWindow() {
        isHidden = false
    }

    func hideWindow() {
        isHidden = true
    }
}
