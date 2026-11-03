//
//  SandboxFilePreview.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// plist / strings are parsed and rendered inline; everything else goes to QuickLook.
    enum SandboxFilePreview {

        static func text(for url: URL) -> String? {
            let ext: String = url.pathExtension.lowercased()
            guard ext == "plist" || ext == "strings" else { return nil }

            guard let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else {
                return nil
            }
            return String(describing: plist)
        }
    }
}
