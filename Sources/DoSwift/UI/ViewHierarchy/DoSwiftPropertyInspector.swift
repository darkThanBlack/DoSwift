//
//  DoSwiftPropertyInspector.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/27.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

/// 属性检查器 - 负责动态属性读取和修改
public class DoSwiftPropertyInspector {

    public static let shared = DoSwiftPropertyInspector()

    private init() {}

    // MARK: - Property Categories

    /// 获取视图的所有属性分类
    public func getPropertyCategories(for view: UIView) -> [DoSwiftPropertyCategory] {
        var categories: [DoSwiftPropertyCategory] = []

        categories.append(getBasicProperties(for: view))
        categories.append(getLayoutProperties(for: view))
        categories.append(getAppearanceProperties(for: view))
        categories.append(getInteractionProperties(for: view))

        if let label = view as? UILabel {
            categories.append(getLabelProperties(for: label))
        }

        if let button = view as? UIButton {
            categories.append(getButtonProperties(for: button))
        }

        if let imageView = view as? UIImageView {
            categories.append(getImageViewProperties(for: imageView))
        }

        return categories
    }

    // MARK: - Basic Properties

    private func getBasicProperties(for view: UIView) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "基础属性", icon: UIImage(systemName: "info.circle"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "类名",
                value: String(describing: type(of: view)),
                type: .readonly,
                keyPath: "",
                targetView: view
            ),
            DoSwiftProperty(
                name: "内存地址",
                value: String(format: "%p", view),
                type: .readonly,
                keyPath: "",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Tag",
                value: view.tag,
                type: .number,
                keyPath: "tag",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Alpha",
                value: view.alpha,
                type: .number,
                keyPath: "alpha",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Hidden",
                value: view.isHidden,
                type: .bool,
                keyPath: "isHidden",
                targetView: view
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - Layout Properties

    private func getLayoutProperties(for view: UIView) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "布局属性", icon: UIImage(systemName: "rectangle"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "Frame",
                value: NSValue(cgRect: view.frame),
                type: .frame,
                keyPath: "frame",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Bounds",
                value: NSValue(cgRect: view.bounds),
                type: .frame,
                keyPath: "bounds",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Center",
                value: NSValue(cgPoint: view.center),
                type: .point,
                keyPath: "center",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Content Mode",
                value: contentModeString(view.contentMode),
                type: .readonly,
                keyPath: "",
                targetView: view
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - Appearance Properties

    private func getAppearanceProperties(for view: UIView) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "外观属性", icon: UIImage(systemName: "paintbrush"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "Background Color",
                value: view.backgroundColor,
                type: .color,
                keyPath: "backgroundColor",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Tint Color",
                value: view.tintColor,
                type: .color,
                keyPath: "tintColor",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Corner Radius",
                value: view.layer.cornerRadius,
                type: .number,
                keyPath: "layer.cornerRadius",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Border Width",
                value: view.layer.borderWidth,
                type: .number,
                keyPath: "layer.borderWidth",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Border Color",
                value: view.layer.borderColor != nil ? UIColor(cgColor: view.layer.borderColor!) : nil,
                type: .color,
                keyPath: "layer.borderColor",
                targetView: view
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - Interaction Properties

    private func getInteractionProperties(for view: UIView) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "交互属性", icon: UIImage(systemName: "hand.tap"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "User Interaction Enabled",
                value: view.isUserInteractionEnabled,
                type: .bool,
                keyPath: "isUserInteractionEnabled",
                targetView: view
            ),
            DoSwiftProperty(
                name: "Clips To Bounds",
                value: view.clipsToBounds,
                type: .bool,
                keyPath: "clipsToBounds",
                targetView: view
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - UILabel Properties

    private func getLabelProperties(for label: UILabel) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "Label 属性", icon: UIImage(systemName: "textformat"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "Text",
                value: label.text,
                type: .string,
                keyPath: "text",
                targetView: label
            ),
            DoSwiftProperty(
                name: "Font",
                value: label.font,
                type: .font,
                keyPath: "font",
                targetView: label
            ),
            DoSwiftProperty(
                name: "Text Color",
                value: label.textColor,
                type: .color,
                keyPath: "textColor",
                targetView: label
            ),
            DoSwiftProperty(
                name: "Text Alignment",
                value: textAlignmentString(label.textAlignment),
                type: .readonly,
                keyPath: "",
                targetView: label
            ),
            DoSwiftProperty(
                name: "Number of Lines",
                value: label.numberOfLines,
                type: .number,
                keyPath: "numberOfLines",
                targetView: label
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - UIButton Properties

    private func getButtonProperties(for button: UIButton) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "Button 属性", icon: UIImage(systemName: "button.programmable"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "Title (Normal)",
                value: button.title(for: .normal),
                type: .string,
                keyPath: "currentTitle",
                targetView: button
            ),
            DoSwiftProperty(
                name: "Title Color (Normal)",
                value: button.titleColor(for: .normal),
                type: .color,
                keyPath: "titleColor",
                targetView: button
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - UIImageView Properties

    private func getImageViewProperties(for imageView: UIImageView) -> DoSwiftPropertyCategory {
        let category = DoSwiftPropertyCategory(name: "ImageView 属性", icon: UIImage(systemName: "photo"))

        let properties: [DoSwiftProperty] = [
            DoSwiftProperty(
                name: "Image",
                value: imageView.image != nil ? "有图片" : "无图片",
                type: .readonly,
                keyPath: "",
                targetView: imageView
            ),
            DoSwiftProperty(
                name: "Highlighted Image",
                value: imageView.highlightedImage != nil ? "有高亮图片" : "无高亮图片",
                type: .readonly,
                keyPath: "",
                targetView: imageView
            )
        ]

        category.properties = properties
        return category
    }

    // MARK: - Property Modification

    /// 修改视图属性
    public func updateProperty(_ property: DoSwiftProperty, newValue: Any?) {
        guard let targetView = property.targetView,
              !property.keyPath.isEmpty else { return }

        do {
            let convertedValue = try convertValue(newValue, for: property.type)
            targetView.setValue(convertedValue, forKeyPath: property.keyPath)

            // 发送属性变更通知
            NotificationCenter.default.post(
                name: .doSwiftHierarchyDidChange,
                object: targetView,
                userInfo: ["property": property, "newValue": convertedValue as Any]
            )

            // 调用回调
            property.valueChangeCallback?(convertedValue)

        } catch {
            print("DoSwift: 属性更新失败 - \(error.localizedDescription)")
        }
    }

    // MARK: - Value Conversion

    private func convertValue(_ value: Any?, for type: DoSwiftPropertyType) throws -> Any? {
        guard let value = value else { return nil }

        switch type {
        case .string:
            return value as? String ?? String(describing: value)

        case .number:
            if let number = value as? NSNumber {
                return number
            } else if let string = value as? String, let double = Double(string) {
                return NSNumber(value: double)
            }
            throw PropertyConversionError.invalidNumberFormat

        case .bool:
            if let bool = value as? Bool {
                return bool
            } else if let number = value as? NSNumber {
                return number.boolValue
            }
            throw PropertyConversionError.invalidBoolFormat

        case .color:
            if let color = value as? UIColor {
                return color
            }
            throw PropertyConversionError.invalidColorFormat

        case .frame:
            if let rectValue = value as? NSValue, rectValue.responds(to: #selector(getter: NSValue.cgRectValue)) {
                return rectValue
            }
            throw PropertyConversionError.invalidFrameFormat

        case .point:
            if let pointValue = value as? NSValue, pointValue.responds(to: #selector(getter: NSValue.cgPointValue)) {
                return pointValue
            }
            throw PropertyConversionError.invalidPointFormat

        default:
            return value
        }
    }

    // MARK: - Helper Methods

    private func contentModeString(_ contentMode: UIView.ContentMode) -> String {
        switch contentMode {
        case .scaleToFill: return "Scale To Fill"
        case .scaleAspectFit: return "Aspect Fit"
        case .scaleAspectFill: return "Aspect Fill"
        case .redraw: return "Redraw"
        case .center: return "Center"
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        @unknown default: return "Unknown"
        }
    }

    private func textAlignmentString(_ alignment: NSTextAlignment) -> String {
        switch alignment {
        case .left: return "Left"
        case .center: return "Center"
        case .right: return "Right"
        case .justified: return "Justified"
        case .natural: return "Natural"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Property Conversion Errors

enum PropertyConversionError: LocalizedError {
    case invalidNumberFormat
    case invalidBoolFormat
    case invalidColorFormat
    case invalidFrameFormat
    case invalidPointFormat

    var errorDescription: String? {
        switch self {
        case .invalidNumberFormat:
            return "无效的数字格式"
        case .invalidBoolFormat:
            return "无效的布尔格式"
        case .invalidColorFormat:
            return "无效的颜色格式"
        case .invalidFrameFormat:
            return "无效的Frame格式"
        case .invalidPointFormat:
            return "无效的Point格式"
        }
    }
}
