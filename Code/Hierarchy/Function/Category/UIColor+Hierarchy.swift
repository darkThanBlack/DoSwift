//
//  UIColor+Hierarchy.swift
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

}

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

    var hierarchy_editableText: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        guard a < 1 else { return rgb }
        return rgb + String(format: "%02X", Int(a * 255))
    }

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

    static func hierarchy_color(from text: String) -> UIColor? {
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
}
