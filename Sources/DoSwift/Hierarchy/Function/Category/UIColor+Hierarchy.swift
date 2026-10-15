//
//  UIColor+Hierarchy.swift
//  DoSwift
//
//  Translated from UIColor+DoraemonHierarchy.m
//

import UIKit

extension UIColor {

    var hierarchy_hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    var hierarchy_description: String {
        if self == UIColor.clear {
            return "Clear Color"
        }

        let colorName = hierarchy_systemColorName
        let rgba = hierarchy_RGBADescription

        if let name = colorName {
            return "\(name) (\(rgba))"
        }
        return rgba
    }

    /// **可编辑形态**：`#RRGGBB`，alpha < 1 时给 `#RRGGBBAA`。
    ///
    /// 和 `hierarchy_description` 的分工要说清：那个是给人读的（系统色会带上色名，
    /// 渲染成 `Red (#FF3B30)`），**它不是合法的输入**；这个是给输入框用的，
    /// 保证 `hierarchy_color(from:)` 一定能读回来。
    var hierarchy_editableText: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        guard a < 1 else { return rgb }
        return rgb + String(format: "%02X", Int(a * 255))
    }

    /// 0–1 的 alpha。取不到分量时按 1 处理（不透明是更安全的默认）。
    var hierarchy_alpha: CGFloat {
        var a: CGFloat = 1
        getRed(nil, green: nil, blue: nil, alpha: &a)
        return a
    }

    var hierarchy_systemColorName: String? {
        value(forKey: "systemColorName") as? String
    }

    var hierarchy_RGBADescription: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        var desc = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        if a < 1.0 {
            desc += String(format: ", Alpha: %0.2f", a)
        }
        return desc
    }

    /// 从文本造颜色 —— `hierarchy_description` / `hierarchy_hexString` 的反向。
    ///
    /// 接受：
    ///   `#RGB` · `#RRGGBB` · `#RRGGBBAA`
    ///   `r, g, b` · `r, g, b, a`（分量都 ≤ 1 时按 0–1 处理，否则按 0–255）
    ///
    /// 造不出返回 nil —— 调用方据此提示"输入不合法"，而不是悄悄设一个黑。
    static func hierarchy_color(from text: String) -> UIColor? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("#") {
            let hex = String(trimmed.dropFirst())
            guard let value = UInt64(hex, radix: 16) else { return nil }
            switch hex.count {
            case 3:     // #RGB → #RRGGBB（每位重复一次）
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

        // 三个分量都不超过 1 就当 0–1，否则当 0–255：两种写法都能一眼看懂
        let scale: Double = numbers.prefix(3).allSatisfy { $0 <= 1 } ? 1 : 255
        return UIColor(red: numbers[0] / scale,
                       green: numbers[1] / scale,
                       blue: numbers[2] / scale,
                       alpha: parts.count == 4 ? (numbers[3] > 1 ? numbers[3] / 255 : numbers[3]) : 1)
    }
}
