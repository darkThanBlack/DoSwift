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
}
