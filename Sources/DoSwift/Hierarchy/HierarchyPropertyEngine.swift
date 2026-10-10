//
//  HierarchyPropertyEngine.swift
//  DoSwift
//
//  JSON-driven property inspector engine.
//  Property lists and enum descriptions are declared in HierarchyProperties.json
//  (types + enums); this file only contains the read-only rendering skeleton.
//  Property write-back (editing) is intentionally deferred to a later pass.
//

import UIKit
import ObjectiveC.runtime

// MARK: - JSON Types

struct HierarchyPropertyItem: Decodable {
    let key: String
    let title: String?
    let editor: String
    let enumType: String?
    let `trueTitle`: String?
    let `falseTitle`: String?
    let label: String?
}

struct HierarchyPropertyGroup: Decodable {
    let title: String
    let items: [HierarchyPropertyItem]
    let isSize: Bool?
}

struct HierarchyPropertiesEntry: Decodable {
    let groups: [HierarchyPropertyGroup]
}

struct HierarchyEnumValue: Decodable {
    let value: Int
    let name: String
}

struct HierarchyPropertiesRoot: Decodable {
    let types: [String: HierarchyPropertiesEntry]
    let enums: [String: [HierarchyEnumValue]]
}

// MARK: - Engine

class HierarchyPropertyEngine {

    static let shared = HierarchyPropertyEngine()

    private var entries: [String: HierarchyPropertiesEntry] = [:]
    private var enumDescriptions: [String: [Int: String]] = [:]

    private init() {
        loadJSON()
    }

    private func loadJSON() {
        guard let url = resolveURL() else {
            print("[Hierarchy] HierarchyProperties.json not found. Check Bundle resource.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let root = try JSONDecoder().decode(HierarchyPropertiesRoot.self, from: data)
            entries = root.types
            enumDescriptions = root.enums.mapValues { values in
                Dictionary(uniqueKeysWithValues: values.map { ($0.value, $0.name) })
            }
        } catch {
            print("[Hierarchy] Failed to load HierarchyProperties.json: \(error)")
        }
    }

    /// Resolves the JSON resource across main bundle, framework bundle, and
    /// CocoaPods `resource_bundles` (a nested `<name>.bundle`).
    private func resolveURL() -> URL? {
        let frameworkBundle = Bundle(for: HierarchyPropertyEngine.self)
        if let url = Bundle.main.url(forResource: "HierarchyProperties", withExtension: "json") {
            return url
        }
        if let url = frameworkBundle.url(forResource: "HierarchyProperties", withExtension: "json") {
            return url
        }
        if let bundleURL = Bundle.main.url(forResource: "DoSwiftResources", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL),
           let url = bundle.url(forResource: "HierarchyProperties", withExtension: "json") {
            return url
        }
        if let bundleURL = frameworkBundle.url(forResource: "DoSwiftResources", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL),
           let url = bundle.url(forResource: "HierarchyProperties", withExtension: "json") {
            return url
        }
        return nil
    }

    // MARK: - Public API

    func categoryModels(for view: UIView) -> [HierarchyCategoryModel] {
        return buildModels(view: view, sizeGroups: false)
    }

    func sizeCategoryModels(for view: UIView) -> [HierarchyCategoryModel] {
        return buildModels(view: view, sizeGroups: true)
    }

    /// 按 key 取单独一行。
    ///
    /// `key` 在同一条类链上唯一（已对 JSON 全量校验：没有一条链上出现重复 key），
    /// 所以**不需要组名参与**——多一个维度就多一处要同步的东西。
    ///
    /// 取不到就返回 nil，这同时回答了两个问题：属性**不适用**（`textColor` 之于 UIView），
    /// 以及值**读不出来**（`backgroundColor` 为 nil）。调用方按「隐藏这一行」处理即可。
    ///
    /// - Parameter compact: 用浮层所需的紧凑格式。详情页要完整信息，浮层只有一行宽，
    ///   两处密度不同但都出自同一份 JSON —— 见 `compactEditors`。
    func cellModel(for view: UIView, key: String, compact: Bool) -> HierarchyCellModel? {
        guard let item = item(for: key, in: view) else { return nil }
        return makeCellModel(for: view, item: item, compact: compact)
    }

    // MARK: - Model Building

    private func buildModels(view: UIView, sizeGroups: Bool) -> [HierarchyCategoryModel] {
        var allGroups: [HierarchyPropertyGroup] = []

        for className in classChain(view) {
            guard let entry = entries[className] else { continue }
            for group in entry.groups {
                let isSize = group.isSize ?? false
                if isSize == sizeGroups {
                    allGroups.append(group)
                }
            }
        }

        // Merge groups with the same title.
        var merged: [(title: String, items: [HierarchyPropertyItem])] = []
        for group in allGroups {
            if let idx = merged.firstIndex(where: { $0.title == group.title }) {
                merged[idx].items.append(contentsOf: group.items)
            } else {
                merged.append((group.title, group.items))
            }
        }

        var result: [HierarchyCategoryModel] = []

        for (groupTitle, items) in merged {
            var cellModels: [HierarchyCellModel] = []
            for item in items {
                guard let cellModel = makeCellModel(for: view, item: item) else { continue }
                cellModels.append(cellModel)
            }
            if !cellModels.isEmpty {
                result.append(HierarchyCategoryModel(title: groupTitle, items: cellModels))
            }
        }

        return result
    }

    // MARK: - Presentation Overrides

    /// 浮层的紧凑 editor，按 key 覆盖 JSON 里的 `editor`。
    ///
    /// JSON 里的格式是**照详情页写的**：UIFont 的 `description` 有三行、颜色是
    /// `R:… G:… B:… A:…` 加一行 hex，塞进浮层那一行会把面板撑开。这里给少数几个 key
    /// 补一个紧凑变体，两种密度仍然出自同一份数据。
    ///
    /// **刻意不改 JSON**：它是唯一数据源，而且详情页正需要那份完整信息。
    private static let compactEditors: [String: String] = [
        "font": "fontSize",
        "backgroundColor": "colorShort",
        "textColor": "colorShort",
        "tintColor": "colorShort",
        "tag": "tagShort",
    ]

    /// JSON 里 `title` 的两处历史遗留，在这里补一层**稀疏覆盖**：
    /// UILabel 的 `textColor` 也叫 "Text"（与 `text` 撞名）、`font` 的 title 是空的。
    /// 拍平成一列之后这两处就再也分不开了，所以必须有人纠一下。
    ///
    /// 放在引擎而不是 JSON：改 JSON 会同时动到详情页的既有显示，而这张表只有两条，
    /// 将来要搬进 JSON 直接删掉即可。
    private static let titleOverrides: [String: String] = [
        "textColor": "Text Color",
        "font": "Font",
    ]

    /// key → JSON item，按类链顺序（父类在前）找到即返回。
    ///
    /// key 在链上唯一，所以「找到即返回」不会漏掉更靠后的同 key 项。
    private func item(for key: String, in view: UIView) -> HierarchyPropertyItem? {
        for className in classChain(view) {
            guard let entry = entries[className] else { continue }
            for group in entry.groups {
                if let item = group.items.first(where: { $0.key == key }) {
                    return item
                }
            }
        }
        return nil
    }

    // MARK: - Per-Item Cell Building

    private func makeCellModel(
        for view: UIView,
        item: HierarchyPropertyItem,
        compact: Bool = false
    ) -> HierarchyCellModel? {
        let key = item.key
        let editor = compact ? (Self.compactEditors[key] ?? item.editor) : item.editor
        let title = Self.titleOverrides[key] ?? item.title

        // Editors that do not read a KVC key path — resolved without KVC.
        switch editor {
        case "className":
            let detail = String(describing: type(of: view))
            return HierarchyCellModel(title: title, detailTitle: detail).noneInsets()

        case "address":
            let detail = String(format: "%p", Int(bitPattern: Unmanaged.passUnretained(view).toOpaque()))
            return HierarchyCellModel(title: title, detailTitle: detail).noneInsets()

        case "layerClass":
            let detail = String(describing: type(of: view.layer))
            return HierarchyCellModel(title: title, detailTitle: detail)

        default:
            break
        }

        // Remaining editors read via KVC; skip items whose key path cannot resolve.
        guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

        switch editor {
        case "readonly":
            return HierarchyCellModel(title: title, detailTitle: formatObject(value)).noneInsets()

        case "bool":
            let flag = value as? Bool ?? false
            let detail = flag ? (item.trueTitle ?? "On") : (item.falseTitle ?? "Off")
            return HierarchyCellModel(title: title ?? item.falseTitle, detailTitle: detail).noneInsets()

        case "tagShort":
            // tag 为 0（默认值）时不占行：detailTitle 给 nil，行自己收起
            let tag = value as? Int ?? (value as? NSNumber)?.intValue ?? 0
            return HierarchyCellModel(title: title, detailTitle: tag == 0 ? nil : "\(tag)").noneInsets()

        case "int":
            let formatted: String
            if let v = value as? Int {
                formatted = "\(v)"
            } else if let v = value as? NSNumber {
                formatted = "\(v.intValue)"
            } else {
                formatted = "\(value)"
            }
            return HierarchyCellModel(title: title, detailTitle: formatted).noneInsets()

        case "double":
            let number = value as? NSNumber ?? NSNumber(value: 0)
            return HierarchyCellModel(title: title, detailTitle: HierarchyFormatterTool.format(number)).noneInsets()

        case "text":
            return HierarchyCellModel(title: title, detailTitle: formatText(value)).noneInsets()

        case "color":
            return HierarchyCellModel(title: title, detailTitle: colorDescription(value as? UIColor)).noneInsets()

        case "colorShort":
            // 浮层一行：走 UIColor+Hierarchy 的短描述（动态色会带上系统色名）
            return HierarchyCellModel(title: title, detailTitle: (value as? UIColor)?.hierarchy_description).noneInsets()

        case "font":
            return HierarchyCellModel(title: title, detailTitle: formatObject(value)).noneInsets()

        case "fontSize":
            // 浮层只要字号；UIFont 的完整描述在这里排不下
            guard let font = value as? UIFont else { return nil }
            return HierarchyCellModel(title: title, detailTitle: String(format: "%0.2f", font.pointSize)).noneInsets()

        case "frame":
            let rect = (value as? NSValue)?.cgRectValue ?? .zero
            return HierarchyCellModel(title: title, detailTitle: HierarchyFormatterTool.string(from: rect)).noneInsets()

        case "point":
            let point = (value as? NSValue)?.cgPointValue ?? .zero
            return HierarchyCellModel(title: title, detailTitle: pointDescription(point)).noneInsets()

        case "size":
            let size = (value as? NSValue)?.cgSizeValue ?? .zero
            return HierarchyCellModel(title: title, detailTitle: sizeDescription(size)).noneInsets()

        case "insets":
            let insets = (value as? NSValue)?.uiEdgeInsetsValue ?? .zero
            return HierarchyCellModel(title: title, detailTitle: insetsTopBottomDescription(insets)).noneInsets()

        case "image":
            return HierarchyCellModel(title: title, detailTitle: formatImage(value as? UIImage)).noneInsets()

        case "date":
            let detail = (value as? Date).flatMap { HierarchyFormatterTool.string(from: $0) } ?? "<null>"
            return HierarchyCellModel(title: title, detailTitle: detail).noneInsets()

        case "attributedTextStyle":
            let detail = (value as? NSAttributedString) != nil ? "Attributed Text" : "Plain Text"
            return HierarchyCellModel(title: title, detailTitle: detail).noneInsets()

        case "enum":
            guard let enumType = item.enumType else { return nil }
            let rawValue = value as? Int ?? 0
            let desc = enumDescription(for: enumType, rawValue: rawValue)
            let detail = item.label.map { "\($0) \(desc)" } ?? desc
            return HierarchyCellModel(title: title, detailTitle: detail).noneInsets()

        default:
            return HierarchyCellModel(title: title, detailTitle: formatObject(value)).noneInsets()
        }
    }

    // MARK: - KeyPath Utilities

    private func classChain(_ view: UIView) -> [String] {
        var chain: [String] = []
        var cls: AnyClass? = type(of: view)
        while let c = cls {
            let name = String(describing: c)
            chain.append(name)
            if name == "NSObject" { break }
            cls = class_getSuperclass(c)
        }
        return chain.reversed()
    }

    /// KVC read that returns nil when the key path does not resolve instead of crashing.
    private func safeValue(forKeyPath keyPath: String, on object: NSObject) -> Any? {
        let components = keyPath.split(separator: ".").map(String.init)
        var current: NSObject = object
        for (i, key) in components.enumerated() {
            guard respondsToGetter(current, key) else { return nil }
            let value = current.value(forKey: key)
            if i == components.count - 1 {
                return value
            }
            guard let next = value as? NSObject else { return nil }
            current = next
        }
        return nil
    }

    /// KVC getter lookup: get<Key>, <key>, is<Key> (also covers getter=is<X> renames).
    private func respondsToGetter(_ object: NSObject, _ key: String) -> Bool {
        let capitalized = key.prefix(1).uppercased() + key.dropFirst()
        for selector in ["get\(capitalized)", key, "is\(capitalized)"] {
            if object.responds(to: NSSelectorFromString(selector)) {
                return true
            }
        }
        return false
    }

    // MARK: - Enum Description

    private func enumDescription(for enumType: String, rawValue: Int) -> String {
        return enumDescriptions[enumType]?[rawValue] ?? "\(rawValue)"
    }

    // MARK: - Formatters

    func colorDescription(_ color: UIColor?) -> String {
        guard let color = color else { return "<nil color>" }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            // Grayscale / dynamic colors: fall back to the white component.
            var w: CGFloat = 0
            color.getWhite(&w, alpha: &a)
            r = w; g = w; b = w
        }
        let desc = String(
            format: "R:%@ G:%@ B:%@ A:%@",
            HierarchyFormatterTool.format(NSNumber(value: Double(r))),
            HierarchyFormatterTool.format(NSNumber(value: Double(g))),
            HierarchyFormatterTool.format(NSNumber(value: Double(b))),
            HierarchyFormatterTool.format(NSNumber(value: Double(a)))
        )
        if let name = color.hierarchy_systemColorName {
            return "\(desc)\n\(name)"
        }
        return "\(desc)\n\(color.hierarchy_hexString)"
    }

    private func formatText(_ value: Any?) -> String {
        if value == nil { return "<nil>" }
        if let s = value as? String {
            return s.isEmpty ? "<empty string>" : s
        }
        return "\(value!)"
    }

    func formatObject(_ value: Any?) -> String {
        if value == nil { return "<nil>" }
        if let s = value as? String {
            return s.isEmpty ? "<empty string>" : s
        }
        return "\(value!)"
    }

    func formatImage(_ image: UIImage?) -> String {
        return image?.description ?? "No image"
    }

    func pointDescription(_ point: CGPoint) -> String {
        return "X: \(HierarchyFormatterTool.format(NSNumber(value: Double(point.x))))   Y: \(HierarchyFormatterTool.format(NSNumber(value: Double(point.y))))"
    }

    func sizeDescription(_ size: CGSize) -> String {
        return "W: \(HierarchyFormatterTool.format(NSNumber(value: Double(size.width))))   H: \(HierarchyFormatterTool.format(NSNumber(value: Double(size.height))))"
    }

    func boolDescription(_ flag: Bool) -> String {
        return flag ? "On" : "Off"
    }

    func insetsTopBottomDescription(_ insets: UIEdgeInsets) -> String {
        let top = HierarchyFormatterTool.format(NSNumber(value: Double(insets.top)))
        let bottom = HierarchyFormatterTool.format(NSNumber(value: Double(insets.bottom)))
        return "top \(top)    bottom \(bottom)"
    }

    func insetsLeftRightDescription(_ insets: UIEdgeInsets) -> String {
        let left = HierarchyFormatterTool.format(NSNumber(value: Double(insets.left)))
        let right = HierarchyFormatterTool.format(NSNumber(value: Double(insets.right)))
        return "left \(left)    right \(right)"
    }
}
