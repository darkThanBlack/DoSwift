//
//  SceneDelegate.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/03
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

import DoSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground

        let root = UIViewController()
        root.view.backgroundColor = .systemBackground
        window.rootViewController = root

        window.makeKeyAndVisible()
        self.window = window

        #if DEBUG
        // It is strongly recommended to pass in an accurate window / scene.
        DO.Core.shared.setup(appScene: windowScene, appWindow: window)
        
        // If you wish monitoring start immediately
        DO.NetworkPlugin.shared.start()
        DO.ConsolePlugin.shared.start()
        
        #endif
    }
}
