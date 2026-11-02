//
//  FileBrowserStyle.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// 文件浏览器的外观收束：一律取系统值（语义色顺带解决深色模式），组件内不直接写颜色。
    /// 只收会随外观变化的东西；尺寸与布局常量就地写字面量 —— 收在这里反而看不出来。
    enum FileBrowserStyle {

        // MARK: - Text

        /// 取内容期间的状态文案（列表藏起来，居中显示）
        static var loadingText: String { return "正在读取…" }

        /// 这一层确实没有内容
        static var emptyText: String { return "空文件夹" }

        // MARK: - Color

        /// 路径条 / 列表背景
        static var backgroundColor: UIColor { return .systemBackground }

        /// 强调色：当前层文字 / 文件夹图标
        static var themeColor: UIColor { return .systemBlue }

        /// 行标题
        static var textColor: UIColor { return .label }

        /// 祖先层文字 / 行副标题 / 文件图标
        static var lightTextColor: UIColor { return .secondaryLabel }

        /// 分隔符 / 尾部箭头
        static var disabledTextColor: UIColor { return .tertiaryLabel }

        /// 行图标底色
        static var iconBackgroundColor: UIColor { return .secondarySystemFill }

        // MARK: - Font

        /// 路径条文字；当前层加粗一档（用于「我在哪」的区分）
        static func pathFont(isCurrent: Bool) -> UIFont {
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            guard isCurrent,
                  let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) else {
                return font
            }
            return UIFont(descriptor: descriptor, size: 0)
        }

        /// 状态文案
        static var stateFont: UIFont { return UIFont.preferredFont(forTextStyle: .footnote) }

        /// 行标题
        static var titleFont: UIFont { return .systemFont(ofSize: 15, weight: .regular) }

        /// 行副标题
        static var detailFont: UIFont { return .systemFont(ofSize: 12, weight: .regular) }

        // MARK: - Image

        static func folderImage() -> UIImage? { return UIImage(systemName: "folder.fill") }

        static func fileImage() -> UIImage? { return UIImage(systemName: "doc.fill") }

        static func arrowImage() -> UIImage? { return UIImage(systemName: "chevron.right") }

        /// 行图标：`nodeIconToken`（SF Symbol 名，优先）→ 按 ``DO.FileNode/nodeKind`` 兜底
        static func nodeImage(_ node: any DO.FileNode) -> UIImage? {
            if let token = node.nodeIconToken, let image = UIImage(systemName: token) {
                return image
            }
            return (node.nodeKind == .folder) ? folderImage() : fileImage()
        }

        /// 图标着色：文件夹走强调色，文件走中性色
        static func nodeTintColor(_ node: any DO.FileNode) -> UIColor {
            return (node.nodeKind == .folder) ? themeColor : lightTextColor
        }

        /// 常见后缀 → SF Symbol 名（业务可在自己 model 里用它算出 ``DO.FileNode/nodeIconToken``）
        static func token(forExtension ext: String?) -> String? {
            switch ext?.lowercased() {
            case "pdf":                                 return "doc.richtext"
            case "doc", "docx", "pages", "txt", "md":   return "doc.text"
            case "xls", "xlsx", "csv", "numbers":       return "chart.bar"
            case "ppt", "pptx", "key":                  return "rectangle.on.rectangle"
            case "png", "jpg", "jpeg", "gif", "bmp", "heic", "webp":  return "photo"
            case "mp3", "wav", "m4a", "aac", "caf":     return "music.note"
            case "mp4", "mov", "avi", "mkv", "m4v":     return "film"
            case "zip", "rar", "7z", "tar", "gz":       return "archivebox"
            default:                                    return nil
            }
        }

        // MARK: - Size

        /// 文件大小（`ByteCountFormatter` 自带本地化与单位进位）
        static func formatSize(_ bytes: Int64) -> String {
            return sizeFormatter.string(fromByteCount: bytes)
        }

        private static let sizeFormatter: ByteCountFormatter = {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter
        }()
    }
}
