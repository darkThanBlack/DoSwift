//
//  HierarchyPropertyEngine.swift
//  DoSwift
//
//  Created by Claude on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit
import ObjectiveC.runtime

extension DO {

    struct HierarchyPropertyOverride: Decodable {
        let enumType: String?
        let desc: String?
        let userEditable: Bool?
    }

    struct HierarchyTypeEntry: Decodable {
        let properties: [String]
        let overrides: [String: DO.HierarchyPropertyOverride]?
    }

    struct HierarchyPinnedGroup: Decodable {
        let group: String
        let properties: [String]
    }

    struct HierarchyEnumValue {
        let value: Int
        let name: String
    }

    enum ValueKind {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case text(String)
        case color(UIColor)
        case font(UIFont)
        case image(UIImage)
        case date(Date)
        case attributedText(NSAttributedString)
        case frame(CGRect)
        case point(CGPoint)
        case size(CGSize)
        case insets(UIEdgeInsets)
        case enumValue(raw: Int, table: String, name: String)
        case unknown(Any)

        /// Classifies a KVC result by its runtime type.
        ///
        /// Order matters. `UIColor`, `UIFont` and `UIImage` are objects, so they have to be
        /// excluded before the `NSNumber` branch; `NSValue` has to be inspected through its
        /// encoding because `CGRect` and `CGSize` arrive as the same class.
        static func probe(_ value: Any) -> DO.ValueKind {
            switch value {
            case is UIColor: return .color(value as! UIColor)

            case let number as NSNumber:
                switch String(cString: number.objCType) {
                case "c", "C", "B": return .bool(number.boolValue)
                case "d", "f":      return .double(number.doubleValue)
                default:            return .int(number.intValue)
                }

            case let box as NSValue:
                let encoding = String(cString: box.objCType)
                if encoding.contains("CGRect")       { return .frame(box.cgRectValue) }
                if encoding.contains("CGPoint")      { return .point(box.cgPointValue) }
                if encoding.contains("CGSize")       { return .size(box.cgSizeValue) }
                if encoding.contains("UIEdgeInsets") { return .insets(box.uiEdgeInsetsValue) }
                return .unknown(value)

            case is UIFont:              return .font(value as! UIFont)
            case is UIImage:             return .image(value as! UIImage)
            case is Date, is NSDate:     return .date(value as! Date)
            case is NSAttributedString:  return .attributedText(value as! NSAttributedString)
            case is String, is NSString: return .text(value as! String)

            default:
                return .unknown(value)
            }
        }

        var boxed: Any {
            switch self {
            case .bool(let v):   return NSNumber(value: v)
            case .int(let v):    return NSNumber(value: v)
            case .double(let v): return NSNumber(value: v)
            case .text(let v):   return v
            case .color(let v):  return v
            case .font(let v):   return v
            case .image(let v):  return v
            case .date(let v):   return v
            case .attributedText(let v): return v
            case .frame(let v):  return NSValue(cgRect: v)
            case .point(let v):  return NSValue(cgPoint: v)
            case .size(let v):   return NSValue(cgSize: v)
            case .insets(let v): return NSValue(uiEdgeInsets: v)
            case .enumValue(let raw, _, _): return NSNumber(value: raw)
            case .unknown(let v): return v
            }
        }
    }

    struct HierarchyPropertiesRoot: Decodable {
        let pinned: [DO.HierarchyPinnedGroup]?
        let types: [String: DO.HierarchyTypeEntry]
        let enums: [String: [String: String]]

        private enum CodingKeys: String, CodingKey {
            case pinned = "Pinned"
            case types
            case enums
        }
    }

    struct HierarchyEditDescriptor {
        let key: String
        let kind: DO.ValueKind
        let writeKey: String
    }

    /// Read-only property panel driven by `HierarchyProperties.json`.
    ///
    /// Nothing here knows about any particular property. The JSON says which class exposes
    /// which keys; this class reads them through KVC and renders one row each. That is what
    /// replaced the original ObjC implementation, where every exposed property was a
    /// hand-written block across several thousand lines.
    ///
    /// Three rules are worth holding on to:
    ///
    /// - Lookup walks the class chain from `NSObject` downwards, so a subclass entry wins
    ///   over its parent's, and the nearest class that declares a key supplies its overrides.
    /// - A key is only shown when the object actually answers the getter. `textColor` is
    ///   declared for `UILabel`; a plain `UIView` has no such key and simply yields no row.
    /// - Writing goes back through the same entry: `userEditable`, plus a `ValueKind` we know
    ///   how to parse, plus a real setter. Miss any of the three and the row stays read-only.
    class HierarchyPropertyEngine {

        static let shared = DO.HierarchyPropertyEngine()

        private var types: [String: DO.HierarchyTypeEntry] = [:]
        private var enumTables: [String: [DO.HierarchyEnumValue]] = [:]

        private var pinnedKeys: [String] = []

        private static let pinnedSectionTitle = "Pinned"

        /// Keys with no KVC counterpart. They are computed from the object itself, so they
        /// never reach `value(forKey:)`.
        private static let syntheticKeys: [String: String] = [
            "class":       "className",
            "address":     "address",
            "layer.class": "layerClass",
        ]

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
                let root = try JSONDecoder().decode(DO.HierarchyPropertiesRoot.self, from: data)
                types = root.types
                enumTables = root.enums.mapValues { table -> [DO.HierarchyEnumValue] in
                    table.compactMap { key, name in
                        Int(key).map { DO.HierarchyEnumValue(value: $0, name: name) }
                    }
                    .sorted { $0.value < $1.value }
                }
                for group in root.pinned ?? [] {
                    for key in group.properties where !pinnedKeys.contains(key) {
                        pinnedKeys.append(key)
                    }
                }
            } catch {
                print("[Hierarchy] Failed to load HierarchyProperties.json: \(error)")
            }
        }

        /// Resolves the JSON resource across main bundle, framework bundle, and
        /// CocoaPods `resource_bundles` (a nested `<name>.bundle`).
        private func resolveURL() -> URL? {
            let frameworkBundle = Bundle(for: DO.HierarchyPropertyEngine.self)
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

        func categoryModels(for view: UIView) -> [DO.HierarchyCategoryModel] {
            let chain = classChain(view)
            var result: [DO.HierarchyCategoryModel] = []

            let pinnedRows = pinnedKeys.compactMap { cellModel(for: view, key: $0, chain: chain) }
            if !pinnedRows.isEmpty {
                result.append(DO.HierarchyCategoryModel(title: Self.pinnedSectionTitle, items: pinnedRows))
            }

            for className in chain {
                guard let entry = types[className] else { continue }
                let rows = entry.properties
                    .filter { !pinnedKeys.contains($0) }
                    .compactMap { cellModel(for: view, key: $0, chain: chain) }
                if !rows.isEmpty {
                    result.append(DO.HierarchyCategoryModel(title: className, items: rows))
                }
            }

            return result
        }

        func cellModel(for view: UIView, key: String) -> DO.HierarchyCellModel? {
            return cellModel(for: view, key: key, chain: classChain(view))
        }

        private struct ResolvedProperty {
            let key: String
            let synthetic: String?
            let kind: DO.ValueKind?
            let desc: String?
            let isUserEditable: Bool
        }

        private func cellModel(for view: UIView, key: String, chain: [String]) -> DO.HierarchyCellModel? {
            guard let resolved = resolve(key: key, view: view, chain: chain),
                  let model = makeCellModel(for: view, resolved: resolved)
            else { return nil }

            if resolved.isUserEditable, let kind = resolved.kind,
               canEdit(kind), let writeKey = kvcWriteKey(for: key, on: view) {
                model.edit = DO.HierarchyEditDescriptor(key: key, kind: kind, writeKey: writeKey)
            }
            return model
        }

        private func resolve(key: String, view: UIView, chain: [String]) -> ResolvedProperty? {
            var override: DO.HierarchyPropertyOverride?
            if !pinnedKeys.contains(key) {
                guard let className = chain.first(where: { types[$0]?.properties.contains(key) == true })
                else { return nil }        // not declared for this chain -> not applicable
                override = types[className]?.overrides?[key]
            }

            let isUserEditable = override?.userEditable ?? true

            if let synthetic = Self.syntheticKeys[key] {
                return ResolvedProperty(key: key, synthetic: synthetic, kind: nil,
                                        desc: override?.desc, isUserEditable: isUserEditable)
            }

            guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

            let kind: DO.ValueKind
            if let table = override?.enumType {
                let raw = (value as? Int) ?? (value as? NSNumber)?.intValue ?? 0
                kind = .enumValue(raw: raw, table: table, name: enumName(table, raw))
            } else {
                kind = DO.ValueKind.probe(value)
            }

            return ResolvedProperty(key: key, synthetic: nil, kind: kind,
                                    desc: override?.desc, isUserEditable: isUserEditable)
        }

        private func makeCellModel(for view: UIView, resolved: ResolvedProperty) -> DO.HierarchyCellModel? {
            let title = resolved.desc ?? resolved.key

            if let synthetic = resolved.synthetic {
                return cell(title, syntheticText(synthetic, view), separator: synthetic == "layerClass")
            }

            guard let kind = resolved.kind else { return nil }

            return cell(title, displayText(of: kind), separator: false)
        }

        private func cell(_ title: String?, _ detail: String?, separator: Bool) -> DO.HierarchyCellModel {
            let model = DO.HierarchyCellModel(title: title, detailTitle: detail)
            if !separator {
                model.noneInsets()
            }
            return model
        }

        func displayText(of kind: DO.ValueKind) -> String {
            switch kind {
            case .bool(let v):          return v ? "true" : "false"
            case .int(let v):           return "\(v)"
            case .double(let v):        return DO.HierarchyFormatterTool.format(NSNumber(value: v))
            case .text(let v):          return formatText(v)
            case .color(let v):         return v.hierarchy_description
            case .font(let v):          return fontDescription(v)
            case .image(let v):         return formatImage(v)
            case .date(let v):          return DO.HierarchyFormatterTool.string(from: v) ?? "<null>"
            case .attributedText:       return "Attributed Text"
            case .frame(let v):         return DO.HierarchyFormatterTool.string(from: v)
            case .point(let v):         return pointDescription(v)
            case .size(let v):          return sizeDescription(v)
            case .insets(let v):        return insetsDescription(v)
            case .enumValue(_, _, let name): return name
            case .unknown(let v):       return formatObject(v)
            }
        }

        func parsed(_ string: String, into kind: DO.ValueKind) -> DO.ValueKind? {
            switch kind {
            case .bool:
                switch string.lowercased() {
                case "true", "1", "yes", "on":  return .bool(true)
                case "false", "0", "no", "off": return .bool(false)
                default:                        return nil
                }

            case .text:
                return .text(string)                        // nothing to parse

            case .enumValue(_, let table, _):
                if let raw = Int(string) { return .enumValue(raw: raw, table: table, name: enumName(table, raw)) }
                guard let hit = enumTables[table]?.first(where: { $0.name.caseInsensitiveCompare(string) == .orderedSame })
                else { return nil }
                return .enumValue(raw: hit.value, table: table, name: hit.name)

            case .int:
                return Int(string).map(DO.ValueKind.int)

            case .double:
                return Double(string).map(DO.ValueKind.double)

            case .color:
                return UIColor.hierarchy_color(from: string).map(DO.ValueKind.color)

            case .font(let current):
                return Double(string).map { DO.ValueKind.font(current.withSize(CGFloat($0))) }

            case .date:
                return DO.HierarchyFormatterTool.date(from: string).map(DO.ValueKind.date)

            case .size, .insets:
                return nil

            case .frame, .point:
                return nil

            case .image, .attributedText:
                return nil

            case .unknown:
                return nil                                  // unknown probe -> no editor
            }
        }

        private func canEdit(_ kind: DO.ValueKind) -> Bool {
            switch kind {
            case .bool, .text, .int, .double, .enumValue,
                 .color, .font, .date, .size, .insets:     return true
            case .image, .attributedText:
                return false
            case .frame, .point:
                return false                                // layout output; edited elsewhere
            case .unknown:
                return false                                // unknown probe
            }
        }

        private func syntheticText(_ synthetic: String, _ view: UIView) -> String {
            switch synthetic {
            case "className":  return String(describing: type(of: view))
            case "layerClass": return String(describing: type(of: view.layer))
            default:           return String(format: "%p", Int(bitPattern: Unmanaged.passUnretained(view).toOpaque()))
            }
        }

        private func enumName(_ table: String, _ rawValue: Int) -> String {
            enumTables[table]?.first { $0.value == rawValue }?.name ?? "\(rawValue)"
        }

        func enumOptions(for enumType: String, currentRawValue: Int)
            -> (names: [String], rawValues: [Int], currentIndex: Int?) {
            guard let table = enumTables[enumType] else { return ([], [], nil) }
            return (table.map(\.name), table.map(\.value), table.firstIndex { $0.value == currentRawValue })
        }

        func enumValue(for enumType: String, at index: Int) -> Int? {
            guard let table = enumTables[enumType], table.indices.contains(index) else { return nil }
            return table[index].value
        }

        /// Applies an edit.
        ///
        /// Every guard here has a matching one in the UI: a row without an edit descriptor
        /// never reaches this method, so a rejection means the JSON and the live value
        /// disagree. Log it; do not crash the host app over a debug panel.
        func write(_ newValue: DO.ValueKind, forKey key: String, to view: UIView) {
            guard let resolved = resolve(key: key, view: view, chain: classChain(view)),
                  resolved.isUserEditable, let oldKind = resolved.kind else {
                print("[Hierarchy] \(key): this row is read-only")
                return
            }
            guard canEdit(oldKind) else {
                print("[Hierarchy] \(key): no editor for this kind yet")
                return
            }
            guard !key.contains(".") else {
                print("[Hierarchy] \(key): key paths are not written from this panel")
                return
            }
            guard let writeKey = kvcWriteKey(for: key, on: view) else { return }

            view.setValue(newValue.boxed, forKey: writeKey)

            view.setNeedsLayout()
            view.invalidateIntrinsicContentSize()
            view.window?.layoutIfNeeded()

        }

        private static func writeKeyCandidates(for propertyName: String) -> [String] {
            var candidates = [propertyName]
            if propertyName.hasPrefix("is"), propertyName.count > 2 {
                let stripped = propertyName.dropFirst(2)
                candidates.append(stripped.prefix(1).lowercased() + stripped.dropFirst())
            }
            return candidates
        }

        /// Finds the setter KVC can actually call. `isHidden` is written through `setHidden:`,
        /// not `setIsHidden:`, which is why there is a second candidate.
        private func kvcWriteKey(for propertyName: String, on object: NSObject) -> String? {
            let candidates = Self.writeKeyCandidates(for: propertyName)
            let setterName = { (name: String) in "set" + name.prefix(1).uppercased() + name.dropFirst() + ":" }

            if let hit = candidates.first(where: { object.responds(to: NSSelectorFromString(setterName($0))) }) {
                return hit
            }
            print("[Hierarchy] \(propertyName): \(type(of: object)) has no setter, "
                + "tried \(candidates.map(setterName))")
            return nil
        }

        /// Superclass chain with `NSObject` first, so sections read base class -> subclass.
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

        private func fontDescription(_ font: UIFont) -> String {
            let isSystem = font.familyName == UIFont.systemFont(ofSize: font.pointSize).familyName
            return String(format: "%@ %0.2f", isSystem ? "System" : font.familyName, font.pointSize)
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
            return "X: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(point.x))))   Y: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(point.y))))"
        }

        func sizeDescription(_ size: CGSize) -> String {
            return "W: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(size.width))))   H: \(DO.HierarchyFormatterTool.format(NSNumber(value: Double(size.height))))"
        }

        func insetsDescription(_ insets: UIEdgeInsets) -> String {
            let f = { (v: CGFloat) in DO.HierarchyFormatterTool.format(NSNumber(value: Double(v))) }
            return "T: \(f(insets.top))   L: \(f(insets.left))   B: \(f(insets.bottom))   R: \(f(insets.right))"
        }
    }
}
