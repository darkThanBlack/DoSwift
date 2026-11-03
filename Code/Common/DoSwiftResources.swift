//
//  DoSwiftResources.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/03
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// This library's own resources: `Localizable.strings` and `DoSwiftHierarchyDefine.json`.
    ///
    /// - SPM: `Bundle.module`, i.e. `DoSwift_DoSwift.bundle`
    /// - CocoaPods: the `resource_bundles` output, `DoSwiftResources.bundle`
    static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let name = "DoSwiftResources"
        let hosts = [Bundle.main, Bundle(for: DO.ResourcesToken.self)]
        for host in hosts {
            if let url = host.url(forResource: name, withExtension: "bundle"),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return Bundle(for: DO.ResourcesToken.self)
        #endif
    }()

    private final class ResourcesToken {}
}
