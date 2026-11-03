//
//  OverlayWindow.swift
//  DoSwift
//
//  Created by moonShadow on 2025/09/26
//  Copyright © 2025 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    @objc(DOOverlayWindow)
    public class OverlayWindow: UIWindow {

        private class Weaker<T: AnyObject> {
            weak var me: T?

            init(_ me: T? = nil) {
                self.me = me
            }
        }

        private var noResponses: [Weaker<UIView>] = []

        public init(frame: CGRect, level: UIWindow.Level = .normal) {
            if let scene = Self.activeWindowScene() {
                super.init(windowScene: scene)
                self.frame = frame
            } else {
                super.init(frame: frame)
            }
            windowLevel = level
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private static func activeWindowScene() -> UIWindowScene? {
            let scenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            return scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        }

        func show() {
            isHidden = false
        }

        func hide() {
            isHidden = true
        }

        func addNoResponseView(_ value: UIView) {
            noResponses.removeAll(where: { $0.me == nil })
            noResponses.append(Weaker(value))
        }

        func removeNoResponseView(_ value: UIView) {
            noResponses.removeAll(where: { $0.me == nil || $0.me === value })
        }

        public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)

            if let hit = view, noResponses.contains(where: { $0.me === hit }) {
                return nil
            }

            return view
        }

    }
}
