//
//  AppDelegate.swift
//  DoSwift
//
//  Created by moonShadow on 2025/09/26
//  Copyright © 2025 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

import DoSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .systemBackground

        let root = UIViewController()
        root.view.backgroundColor = .systemBackground
        window.rootViewController = root

        window.makeKeyAndVisible()
        self.window = window

        #if DEBUG
        DO.Core.shared.setup(appWindow: window)
        #endif

        return true
    }
}
