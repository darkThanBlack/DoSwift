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

    /// File browser appearance: system values only (semantic colors, dark mode comes free).
    /// Only things that vary with appearance live here; sizes stay inline.
    enum FileBrowserStyle {

        // MARK: - Text

        /// Shown centered while loading.
        static var loadingText: String { return DO.Text.FileBrowser.loading }

        /// Shown when the level is empty.
        static var emptyText: String { return DO.Text.FileBrowser.emptyFolder }

        // MARK: - Color

        /// Path bar and list background.
        static var backgroundColor: UIColor { return .systemBackground }

        /// Accent: current crumb, folder icon.
        static var themeColor: UIColor { return .systemBlue }

        /// Row title.
        static var textColor: UIColor { return .label }

        /// Ancestor crumbs, row subtitle, file icon.
        static var lightTextColor: UIColor { return .secondaryLabel }

        /// Separators and chevron.
        static var disabledTextColor: UIColor { return .tertiaryLabel }

        /// Icon box background.
        static var iconBackgroundColor: UIColor { return .secondarySystemFill }

        // MARK: - Font

        /// Crumb text; the current one is bolder.
        static func pathFont(isCurrent: Bool) -> UIFont {
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            guard isCurrent,
                  let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) else {
                return font
            }
            return UIFont(descriptor: descriptor, size: 0)
        }

        /// State text.
        static var stateFont: UIFont { return UIFont.preferredFont(forTextStyle: .footnote) }

        /// Row title.
        static var titleFont: UIFont { return .systemFont(ofSize: 15, weight: .regular) }

        /// Row subtitle.
        static var detailFont: UIFont { return .systemFont(ofSize: 12, weight: .regular) }

        // MARK: - Image

        static func folderImage() -> UIImage? { return UIImage(systemName: "folder.fill") }

        static func fileImage() -> UIImage? { return UIImage(systemName: "doc.fill") }

        static func arrowImage() -> UIImage? { return UIImage(systemName: "chevron.right") }

        /// Row icon: `nodeIconToken` first, then ``DO.FileNode/nodeKind``.
        static func nodeImage(_ node: any DO.FileNode) -> UIImage? {
            if let token = node.nodeIconToken, let image = UIImage(systemName: token) {
                return image
            }
            return (node.nodeKind == .folder) ? folderImage() : fileImage()
        }

        /// Tint: accent for folders, neutral for files.
        static func nodeTintColor(_ node: any DO.FileNode) -> UIColor {
            return (node.nodeKind == .folder) ? themeColor : lightTextColor
        }

        /// Extension → SF Symbol, optionally used by a model's `nodeIconToken`.
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

        /// File size; `ByteCountFormatter` handles localization and units.
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
