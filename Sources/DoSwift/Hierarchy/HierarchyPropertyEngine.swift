//
//  HierarchyPropertyEngine.swift
//  DoSwift
//
//  JSON-driven property inspector engine.
//
//  HierarchyProperties.json 只管两件事：
//
//   1. **某个类型展示哪些字段** —— `types` 里每类一个 `properties` 数组，
//      数组顺序即展示顺序。被抽进置顶段的字段不在这里出现（见 `Pinned`）。
//   2. **哪些字段的展示方式推不出来** —— 只有这些才写进 `overrides`。
//      绝大多数 editor 由值探针定，见 `probe(_:)`。
//
//  `Pinned` 是一段跨类的置顶区，条目的 `group` 只为人阅读服务，引擎不看它——
//  属性能不能显示由类链决定，不由这个标签决定。
//
//  `enums` 是 rawValue → 文案的映射，运行时无从推导，必须写在数据里。
//
//  回填（编辑）仍未实现，本文件只读。
//

import UIKit
import ObjectiveC.runtime

// MARK: - JSON Types

/// 单个字段的展示覆盖。**三个字段全可选**：没有条目、或条目为空对象，都走值探针。
struct HierarchyPropertyOverride: Decodable {
    /// 渲染方式。不写就由值探针推。
    let editor: String?
    /// 枚举表名。写了它即表示这是个枚举（值在 KVC 边界上只剩裸 Int）。
    let enumType: String?
    /// 行标题。不写就用 key 本身——`isHidden` 比任何译文都准。
    let desc: String?
}

struct HierarchyTypeEntry: Decodable {
    /// 该类型展示的字段，**顺序即展示顺序**
    let properties: [String]
    let overrides: [String: HierarchyPropertyOverride]?
}

/// 置顶段的一个来源分块。`group` 是给读 JSON 的人看的：它让置顶列表按来源类
/// 分块，并让「这个 key 是从哪儿抽出来的」自明。引擎不用它。
struct HierarchyPinnedGroup: Decodable {
    let group: String
    let properties: [String]
}

struct HierarchyEnumValue: Decodable {
    let value: Int
    let name: String
}

struct HierarchyPropertiesRoot: Decodable {
    /// 置顶段。整块删掉也能跑，删了就只剩按类链分的段。
    let pinned: [HierarchyPinnedGroup]?
    let types: [String: HierarchyTypeEntry]
    let enums: [String: [HierarchyEnumValue]]

    private enum CodingKeys: String, CodingKey {
        // 键名大小写不齐（`types`/`enums` 小写）是刻意的：这个键名同时就是段标题，
        // 不为 title 再设一个字段。
        case pinned = "Pinned"
        case types
        case enums
    }
}

// MARK: - Engine

class HierarchyPropertyEngine {

    static let shared = HierarchyPropertyEngine()

    private var types: [String: HierarchyTypeEntry] = [:]
    private var enumDescriptions: [String: [Int: String]] = [:]

    /// 置顶段的 key，**顺序即文案顺序**（与类链无关）
    private var pinnedKeys: [String] = []
    private var pinnedSet: Set<String> = []
    /// key → 它被抽出来的那个类。用于判断这个 key 在当前 view 上适不适用。
    private var pinnedOwner: [String: String] = [:]

    /// 置顶段标题就是 JSON 的键名，不另设 title 字段
    private static let pinnedSectionTitle = "Pinned"

    /// 段标题默认由类名派生（去 `UI` 前缀 + 驼峰拆词），只有这两处对不上
    private static let sectionTitleOverrides: [String: String] = [
        "NSObject": "Object",
        "UIToolbar": "Tool Bar",
    ]

    /// 不读 KVC、靠自己合成的 editor
    private static let syntheticEditors: Set<String> = ["className", "address", "layerClass"]

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
            types = root.types
            enumDescriptions = root.enums.mapValues { values in
                Dictionary(uniqueKeysWithValues: values.map { ($0.value, $0.name) })
            }
            for group in root.pinned ?? [] {
                for key in group.properties {
                    pinnedKeys.append(key)
                    pinnedOwner[key] = group.group
                }
            }
            pinnedSet = Set(pinnedKeys)
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

    /// 一个 view 的完整属性面板：**置顶段在前，其余按类链分段（父类在前）**。
    ///
    /// 段序完全来自类链——JSON 里没有跨类的顺序数据可供贡献，每类的 `properties`
    /// 只决定类内顺序。被抽进置顶段的 key 不再在原段里重复出现。
    func categoryModels(for view: UIView) -> [HierarchyCategoryModel] {
        let chain = classChain(view)
        var result: [HierarchyCategoryModel] = []

        let pinnedRows = pinnedKeys.compactMap { cellModel(for: view, key: $0, compact: false, chain: chain) }
        if !pinnedRows.isEmpty {
            result.append(HierarchyCategoryModel(title: Self.pinnedSectionTitle, items: pinnedRows))
        }

        for className in chain {
            guard let entry = types[className] else { continue }
            let rows = entry.properties
                .filter { !pinnedSet.contains($0) }
                .compactMap { cellModel(for: view, key: $0, compact: false, chain: chain) }
            if !rows.isEmpty {
                result.append(HierarchyCategoryModel(title: sectionTitle(for: className), items: rows))
            }
        }

        return result
    }

    /// 按 key 取单独一行。
    ///
    /// key 有**两处**来源——置顶段和 `types`。浮层问的 `frame` 在置顶段里，所以两处都得查，
    /// 否则浮层会少一行。
    ///
    /// 取不到就返回 nil，这同时回答了两个问题：属性**不适用**（`textColor` 之于 UIView），
    /// 以及值**读不出来**（`backgroundColor` 为 nil）。调用方按「隐藏这一行」处理即可。
    ///
    /// - Parameter compact: 用浮层所需的紧凑格式。详情页要完整信息，浮层只有一行宽，
    ///   两处密度不同但都出自同一份 JSON —— 见 `compactEditors`。
    func cellModel(for view: UIView, key: String, compact: Bool) -> HierarchyCellModel? {
        return cellModel(for: view, key: key, compact: compact, chain: classChain(view))
    }

    // MARK: - Key Resolution

    /// 一个字段解析完的样子
    private struct ResolvedProperty {
        let key: String
        let editor: String
        let enumType: String?
        let desc: String?
        /// 合成行（`class` / `address` / `layer.class`）不读值，这里是 nil
        let value: Any?
    }

    private func cellModel(for view: UIView, key: String, compact: Bool, chain: [String]) -> HierarchyCellModel? {
        guard let resolved = resolve(key: key, view: view, chain: chain) else { return nil }
        return makeCellModel(for: view, resolved: resolved, compact: compact)
    }

    /// 定下这个 key 在这个 view 上用哪个 editor、值是什么；不适用则返回 nil。
    ///
    /// 适用性：置顶段命中（且来源类在链上）算适用；否则沿类链**父类在前**找第一个
    /// 声明该 key 的类。editor 的优先级是 **覆盖 > 探针**：覆盖写了 `editor` 就用它，
    /// 只写了 `enumType` 就按枚举处理，都没有才看值的形状。
    private func resolve(key: String, view: UIView, chain: [String]) -> ResolvedProperty? {
        // 先定「适不适用」并取出覆盖。置顶段的条目在 JSON 里不重复写覆盖，所以那条路 override 恒为 nil。
        var override: HierarchyPropertyOverride?
        var isApplicable = false

        if let owner = pinnedOwner[key], chain.contains(owner) {
            isApplicable = true
        } else {
            for className in chain {
                guard let entry = types[className], entry.properties.contains(key) else { continue }
                isApplicable = true
                override = entry.overrides?[key]
                break
            }
        }
        guard isApplicable else { return nil }

        // 合成行不读 KVC：它们要的是类型名或地址，没有「值」可探
        if let editor = override?.editor, Self.syntheticEditors.contains(editor) {
            return ResolvedProperty(key: key, editor: editor, enumType: nil, desc: override?.desc, value: nil)
        }

        // 读不出值的字段直接不占行——`textColor` 之于 UIView、`backgroundColor` 为 nil
        guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

        let editor = override?.editor
            ?? (override?.enumType != nil ? "enum" : nil)
            ?? probe(value)

        return ResolvedProperty(key: key, editor: editor, enumType: override?.enumType, desc: override?.desc, value: value)
    }

    /// 值 → editor。
    ///
    /// **`NSNumber` 必须排在 `NSValue` 之前**——它是 `NSValue` 的子类，反过来的话
    /// 所有标量都会落进 NSValue 那支，而那里没有 `q` / `c` / `d` 的分支。
    ///
    /// 判布尔**不能用 `as? Bool`**：实测它对 `CGFloat(1.0)` 返回 true、对 `Int(0)` 返回 false，
    /// 是值相关的，不是类型判断。`objCType` 才是可靠判据。
    private func probe(_ value: Any) -> String {
        switch value {
        case is UIColor:
            return "color"

        case let number as NSNumber:
            switch String(cString: number.objCType) {
            case "c", "C", "B": return "bool"
            case "d", "f":      return "double"
            default:            return "int"
            }

        case let box as NSValue:
            // 取包含而非全等：结构体编码在 32/64 位、float/double 下写法不同
            let encoding = String(cString: box.objCType)
            if encoding.contains("CGRect")       { return "frame" }
            if encoding.contains("CGPoint")      { return "point" }
            if encoding.contains("CGSize")       { return "size" }
            if encoding.contains("UIEdgeInsets") { return "insets" }
            return "readonly"

        case is UIFont:              return "font"
        case is UIImage:             return "image"
        case is Date, is NSDate:     return "date"
        case is NSAttributedString:  return "attributedTextStyle"
        case is String, is NSString: return "text"

        default:
            return "readonly"
        }
    }

    // MARK: - Presentation Overrides

    /// 浮层的紧凑 editor，按 key 覆盖已定下的 editor。
    ///
    /// JSON 里的格式是**照详情页写的**：UIFont 的 `description` 有三行、颜色是
    /// `R:… G:… B:… A:…` 加一行 hex，塞进浮层那一行会把面板撑开。这里给少数几个 key
    /// 补一个紧凑变体，两种密度仍然出自同一份数据。
    private static let compactEditors: [String: String] = [
        "font": "fontSize",
        "backgroundColor": "colorShort",
        "textColor": "colorShort",
        "tintColor": "colorShort",
        "tag": "tagShort",
    ]

    /// 段标题 = 声明该段的那个类。派生规则与 JSON 里原本手写的 28 个标题逐字一致。
    private func sectionTitle(for className: String) -> String {
        if let title = Self.sectionTitleOverrides[className] { return title }
        let stripped = className.hasPrefix("UI") ? String(className.dropFirst(2)) : className
        var result = ""
        for (index, character) in stripped.enumerated() {
            if index > 0, character.isUppercase { result.append(" ") }
            result.append(character)
        }
        return result
    }

    // MARK: - Per-Item Cell Building

    private func makeCellModel(for view: UIView, resolved: ResolvedProperty, compact: Bool) -> HierarchyCellModel? {
        let key = resolved.key
        let editor = compact ? (Self.compactEditors[key] ?? resolved.editor) : resolved.editor
        // 没有 desc 就用 key 本身
        let title = resolved.desc ?? key
        let value = resolved.value

        switch editor {
        case "className":
            return cell(title, String(describing: type(of: view)), editor)

        case "address":
            let detail = String(format: "%p", Int(bitPattern: Unmanaged.passUnretained(view).toOpaque()))
            return cell(title, detail, editor)

        case "layerClass":
            return cell(title, String(describing: type(of: view.layer)), editor)

        case "readonly":
            return cell(title, formatObject(value), editor)

        case "bool":
            // editor 由探针或 JSON 定为 bool，值必然取到了 BOOL
            return cell(title, (value as? Bool ?? false) ? "true" : "false", editor)

        case "tagShort":
            let tag = value as? Int ?? (value as? NSNumber)?.intValue ?? 0
            return cell(title, tag == 0 ? nil : "\(tag)", editor)

        case "int":
            let formatted: String
            if let v = value as? Int {
                formatted = "\(v)"
            } else if let n = value as? NSNumber {
                formatted = "\(n.intValue)"
            } else {
                formatted = "\(value ?? "-")"
            }
            return cell(title, formatted, editor)

        case "double":
            let number = value as? NSNumber ?? NSNumber(value: 0)
            return cell(title, HierarchyFormatterTool.format(number), editor)

        case "text":
            return cell(title, formatText(value), editor)

        case "color":
            return cell(title, colorDescription(value as? UIColor), editor)

        case "colorShort":
            // 浮层一行：走 UIColor+Hierarchy 的短描述（动态色会带上系统色名）
            return cell(title, (value as? UIColor)?.hierarchy_description, editor)

        case "font":
            return cell(title, formatObject(value), editor)

        case "fontSize":
            // 浮层只要字号；UIFont 的完整描述在这里排不下
            guard let font = value as? UIFont else { return nil }
            return cell(title, String(format: "%0.2f", font.pointSize), editor)

        case "frame":
            let rect = (value as? NSValue)?.cgRectValue ?? .zero
            return cell(title, HierarchyFormatterTool.string(from: rect), editor)

        case "point":
            let point = (value as? NSValue)?.cgPointValue ?? .zero
            return cell(title, pointDescription(point), editor)

        case "size":
            let size = (value as? NSValue)?.cgSizeValue ?? .zero
            return cell(title, sizeDescription(size), editor)

        case "insets":
            let insets = (value as? NSValue)?.uiEdgeInsetsValue ?? .zero
            return cell(title, insetsTopBottomDescription(insets), editor)

        case "image":
            return cell(title, formatImage(value as? UIImage), editor)

        case "date":
            let detail = (value as? Date).flatMap { HierarchyFormatterTool.string(from: $0) } ?? "<null>"
            return cell(title, detail, editor)

        case "attributedTextStyle":
            let detail = (value as? NSAttributedString) != nil ? "Attributed Text" : "Plain Text"
            return cell(title, detail, editor)

        case "enum":
            guard let enumType = resolved.enumType else { return nil }
            let rawValue = value as? Int ?? 0
            return cell(title, enumDescription(for: enumType, rawValue: rawValue), editor)

        default:
            return cell(title, formatObject(value), editor)
        }
    }

    /// 造一行。分隔线的显隐是**逐行**的：除 `layer.class` 外都不显示分隔线
    /// （沿用本仓库现状，不是这次改动引入的规则）。
    private func cell(_ title: String?, _ detail: String?, _ editor: String) -> HierarchyCellModel {
        let model = HierarchyCellModel(title: title, detailTitle: detail)
        if editor != "layerClass" {
            model.noneInsets()
        }
        return model
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

    func insetsTopBottomDescription(_ insets: UIEdgeInsets) -> String {
        let top = HierarchyFormatterTool.format(NSNumber(value: Double(insets.top)))
        let bottom = HierarchyFormatterTool.format(NSNumber(value: Double(insets.bottom)))
        return "top \(top)    bottom \(bottom)"
    }
}
