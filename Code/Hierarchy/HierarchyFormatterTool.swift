//
//  HierarchyFormatterTool.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    class HierarchyFormatterTool {
        static let shared = DO.HierarchyFormatterTool()

        private lazy var formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return f
        }()

        private lazy var numberFormatter: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.maximumFractionDigits = 2
            f.usesGroupingSeparator = false
            return f
        }()

        func string(from date: Date) -> String? {
            formatter.string(from: date)
        }

        func date(from string: String) -> Date? {
            formatter.date(from: string)
        }

        func format(_ number: NSNumber) -> String {
            numberFormatter.string(from: number) ?? "\(number)"
        }

        static func string(from date: Date) -> String? {
            shared.string(from: date)
        }

        static func date(from string: String) -> Date? {
            shared.date(from: string)
        }

        static func format(_ number: NSNumber) -> String {
            shared.format(number)
        }

        static func string(from frame: CGRect) -> String {
            "{{\(format(NSNumber(value: frame.origin.x))), \(format(NSNumber(value: frame.origin.y)))}, {\(format(NSNumber(value: frame.size.width))), \(format(NSNumber(value: frame.size.height)))}}"
        }
    }
}

// MARK: - Color

/// Color formatting for the hierarchy panel. Statics on this tool rather than a `UIColor`
/// extension, so the library adds nothing to UIKit types.
extension DO.HierarchyFormatterTool {

    /// Human-readable form: `System Blue (#007AFF)` when the color carries a system name,
    /// otherwise just the RGBA description.
    static func description(of color: UIColor) -> String {
        if color == UIColor.clear {
            return "Clear Color"
        }

        let rgba = rgbaDescription(of: color)
        if let name = systemColorName(of: color) {
            return "\(name) (\(rgba))"
        }
        return rgba
    }

    /// `#RRGGBB`, with `AA` appended only when the color is not opaque — the editor parses
    /// this exact shape back.
    static func editableText(of color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        guard a < 1 else { return rgb }
        return rgb + String(format: "%02X", Int(a * 255))
    }

    static func alpha(of color: UIColor) -> CGFloat {
        var a: CGFloat = 1
        color.getRed(nil, green: nil, blue: nil, alpha: &a)
        return a
    }

    /// Accepts `#RGB`, `#RRGGBB`, `#RRGGBBAA`, or 3 / 4 comma separated numbers
    /// (0...1 or 0...255).
    static func color(from text: String) -> UIColor? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("#") {
            let hex = String(trimmed.dropFirst())
            guard let value = UInt64(hex, radix: 16) else { return nil }
            switch hex.count {
            case 3:
                let r = (value >> 8) & 0xF, g = (value >> 4) & 0xF, b = value & 0xF
                return UIColor(red: CGFloat(r * 17) / 255, green: CGFloat(g * 17) / 255,
                               blue: CGFloat(b * 17) / 255, alpha: 1)
            case 6:
                return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                               green: CGFloat((value >> 8) & 0xFF) / 255,
                               blue: CGFloat(value & 0xFF) / 255, alpha: 1)
            case 8:
                return UIColor(red: CGFloat((value >> 24) & 0xFF) / 255,
                               green: CGFloat((value >> 16) & 0xFF) / 255,
                               blue: CGFloat((value >> 8) & 0xFF) / 255,
                               alpha: CGFloat(value & 0xFF) / 255)
            default:
                return nil
            }
        }

        let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3 || parts.count == 4 else { return nil }
        let numbers = parts.compactMap { Double($0) }
        guard numbers.count == parts.count else { return nil }

        let scale: Double = numbers.prefix(3).allSatisfy { $0 <= 1 } ? 1 : 255
        return UIColor(red: numbers[0] / scale,
                       green: numbers[1] / scale,
                       blue: numbers[2] / scale,
                       alpha: parts.count == 4 ? (numbers[3] > 1 ? numbers[3] / 255 : numbers[3]) : 1)
    }

    private static func rgbaDescription(of color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        var desc = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        if a < 1.0 {
            desc += String(format: ", Alpha: %0.2f", a)
        }
        return desc
    }

    /// UIKit keeps the system palette names private; this is the only way to tell
    /// `.systemBlue` and a hand-built blue apart.
    private static func systemColorName(of color: UIColor) -> String? {
        return color.value(forKey: "systemColorName") as? String
    }
}
