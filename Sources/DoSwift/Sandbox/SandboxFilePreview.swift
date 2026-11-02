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

    /// 沙盒文件预览的「就地渲染」判断。
    ///
    /// plist / strings 这类结构化文本没必要交给 QuickLook：解析出来直接看更清楚
    /// （与 DoKit 原版一致）。其余文件（文本 / 图片 / PDF / 音视频 / Office…）一律走系统
    /// `QLPreviewController`。
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
