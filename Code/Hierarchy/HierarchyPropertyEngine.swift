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

    /// One JSON group: a section title plus the keys it lists, in display order.
    struct HierarchyGroup: Decodable {
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

        /// Classifies a KVC result by runtime type. Order matters: `UIColor` / `UIFont` /
        /// `UIImage` are objects and must precede `NSNumber`, and `NSValue` needs its encoding
        /// inspected because `CGRect` and `CGSize` share a class.
        static func probe(_ value: Any) -> DO.ValueKind {
            switch value {
            case let color as UIColor: return .color(color)

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

            case let font as UIFont:                   return .font(font)
            case let image as UIImage:                 return .image(image)
            case let date as Date:                     return .date(date)
            case let attributed as NSAttributedString: return .attributedText(attributed)
            case let text as String:                   return .text(text)
            case let cls as AnyClass:                  return .unknown(String(describing: cls))

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

    struct DoSwiftHierarchyDefineRoot: Decodable {
        let groups: [DO.HierarchyGroup]?
        let types: [String: DO.HierarchyTypeEntry]
        let enums: [String: [String: String]]

        private enum CodingKeys: String, CodingKey {
            case groups = "Pinned"
            case types
            case enums
        }
    }

    struct HierarchyEditDescriptor {
        let key: String
        let kind: DO.ValueKind
        let writeKey: String
    }

    /// Property panel driven by `DoSwiftHierarchyDefine.json`.
    ///
    /// The JSON says which class exposes which keys; this class reads them with KVC and renders
    /// one row each. Lookup walks the class chain from `NSObject` down, so a subclass entry wins
    /// and the nearest declaring class supplies the overrides. A key only shows when the object
    /// answers its getter. Writing needs `userEditable`, a parseable `ValueKind` and a real
    /// setter — miss one and the row stays read-only.
    class HierarchyPropertyEngine {

        static let shared = DO.HierarchyPropertyEngine()

        private var types: [String: DO.HierarchyTypeEntry] = [:]
        private var enumTables: [String: [DO.HierarchyEnumValue]] = [:]

        /// Groups are rendered first, in JSON order; every key appears at most once.
        private var groups: [DO.HierarchyGroup] = []

        private init() {
            loadJSON()
        }

        private func loadJSON() {
            guard let url = resolveURL() else {
                print("[Hierarchy] DoSwiftHierarchyDefine.json not found. Check Bundle resource.")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                let root = try JSONDecoder().decode(DO.DoSwiftHierarchyDefineRoot.self, from: data)
                types = root.types
                enumTables = root.enums.mapValues { table -> [DO.HierarchyEnumValue] in
                    table.compactMap { key, name in
                        Int(key).map { DO.HierarchyEnumValue(value: $0, name: name) }
                    }
                    .sorted { $0.value < $1.value }
                }
                groups = root.groups ?? []
            } catch {
                print("[Hierarchy] Failed to load DoSwiftHierarchyDefine.json: \(error)")
            }
        }

        /// Resolves the JSON resource: a host that drops the file into the main bundle wins,
        /// otherwise it comes from `DO.resourceBundle` (SPM → `Bundle.module`,
        /// CocoaPods → `DoSwiftKitResources.bundle`).
        private func resolveURL() -> URL? {
            if let url = Bundle.main.url(forResource: "DoSwiftHierarchyDefine", withExtension: "json") {
                return url
            }
            return DO.resourceBundle.url(forResource: "DoSwiftHierarchyDefine", withExtension: "json")
        }

        /// JSON groups first (their own titles and order), then the class chain from NSObject
        /// down. A key rendered by a group is not repeated in a class section.
        func categoryModels(for view: UIView) -> [DO.HierarchyCategoryModel] {
            let chain = classChain(view)
            var result: [DO.HierarchyCategoryModel] = []
            var rendered: Set<String> = []

            for group in groups {
                let rows = group.properties.compactMap { key -> DO.HierarchyCellModel? in
                    guard !rendered.contains(key) else { return nil }
                    guard let model = cellModel(for: view, key: key, chain: chain, requiresDeclaration: false)
                    else { return nil }
                    rendered.insert(key)
                    return model
                }
                if !rows.isEmpty {
                    result.append(DO.HierarchyCategoryModel(title: group.group, items: rows))
                }
            }

            for className in chain {
                guard let entry = types[className] else { continue }
                let rows = entry.properties
                    .filter { !rendered.contains($0) }
                    .compactMap { cellModel(for: view, key: $0, chain: chain, requiresDeclaration: true) }
                if !rows.isEmpty {
                    result.append(DO.HierarchyCategoryModel(title: className, items: rows))
                }
            }

            return result
        }

        func cellModel(for view: UIView, key: String) -> DO.HierarchyCellModel? {
            return cellModel(for: view, key: key, chain: classChain(view), requiresDeclaration: false)
        }

        private struct ResolvedProperty {
            let key: String
            let kind: DO.ValueKind?
            let desc: String?
            let isUserEditable: Bool
        }

        private func cellModel(
            for view: UIView,
            key: String,
            chain: [String],
            requiresDeclaration: Bool
        ) -> DO.HierarchyCellModel? {
            guard let resolved = resolve(key: key, view: view, chain: chain,
                                         requiresDeclaration: requiresDeclaration),
                  let model = makeCellModel(for: view, resolved: resolved)
            else { return nil }

            if resolved.isUserEditable, let kind = resolved.kind, canEdit(kind),
               !key.contains("."), let writeKey = kvcWriteKey(for: key, on: view) {
                model.edit = DO.HierarchyEditDescriptor(key: key, kind: kind, writeKey: writeKey)
            }
            return model
        }

        private func resolve(
            key: String,
            view: UIView,
            chain: [String],
            requiresDeclaration: Bool
        ) -> ResolvedProperty? {
            // The nearest class that declares the key also supplies its overrides; group keys
            // can resolve without a declaration but still pick up an override when one exists.
            let declaring = chain.first { types[$0]?.properties.contains(key) == true }
            if requiresDeclaration, declaring == nil { return nil }

            let override = declaring.flatMap { types[$0]?.overrides?[key] }
            let isUserEditable = override?.userEditable ?? true

            guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

            let kind: DO.ValueKind
            if let table = override?.enumType {
                let raw = (value as? Int) ?? (value as? NSNumber)?.intValue ?? 0
                kind = .enumValue(raw: raw, table: table, name: enumName(table, raw))
            } else {
                kind = DO.ValueKind.probe(value)
            }

            return ResolvedProperty(key: key, kind: kind,
                                    desc: override?.desc, isUserEditable: isUserEditable)
        }

        private func makeCellModel(for view: UIView, resolved: ResolvedProperty) -> DO.HierarchyCellModel? {
            guard let kind = resolved.kind else { return nil }

            let model = DO.HierarchyCellModel(title: resolved.desc ?? resolved.key,
                                              detailTitle: displayText(of: kind))
            model.noneInsets()
            return model
        }

        func displayText(of kind: DO.ValueKind) -> String {
            switch kind {
            case .bool(let v):          return v ? "true" : "false"
            case .int(let v):           return "\(v)"
            case .double(let v):        return DO.HierarchyFormatterTool.format(NSNumber(value: v))
            case .text(let v):          return formatText(v)
            case .color(let v):         return DO.HierarchyFormatterTool.description(of: v)
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
                return DO.HierarchyFormatterTool.color(from: string).map(DO.ValueKind.color)

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
                 .color, .font, .date, .size, .insets,
                 .frame, .point:                            return true
            case .image, .attributedText:
                return false
            case .unknown:
                return false                                // unknown probe
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

        /// Applies an edit. Each guard mirrors one in the UI, so a rejection means the JSON and
        /// the live value disagree — log it, never crash the host app over a debug panel.
        func write(_ newValue: DO.ValueKind, forKey key: String, to view: UIView) {
            guard let resolved = resolve(key: key, view: view, chain: classChain(view),
                                        requiresDeclaration: false),
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
            guard let value = value else { return "<nil>" }
            if let s = value as? String {
                return s.isEmpty ? "<empty string>" : s
            }
            return "\(value)"
        }

        func formatObject(_ value: Any?) -> String {
            guard let value = value else { return "<nil>" }
            if let s = value as? String {
                return s.isEmpty ? "<empty string>" : s
            }
            return "\(value)"
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
