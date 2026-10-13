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
//   2. **三件推不出来的事** —— 只有这些才写进 `overrides`：枚举表名、行标题、
//      这一行给不给编辑器。**展示方式不在其中**：由值探针定，见 `probe(_:)`，
//      只有三个合成行例外（见 `syntheticKeys`）。
//
//  `Pinned` 是一段跨类的置顶区，条目的 `group` 只为人阅读服务，引擎不看它——
//  属性能不能显示由类链决定，不由这个标签决定。
//
//  `enums` 是 rawValue → 文案的映射，运行时无从推导，必须写在数据里。
//
//  回填（编辑）仍未实现，本文件只读；`isUserEditable` 目前只为编辑功能把数据带到位。
//

import UIKit
import ObjectiveC.runtime

// MARK: - JSON Types

/// 单个字段的补充信息。**三个字段全可选**：没有条目、或条目为空对象，都走默认规则。
///
/// 这里只放**推不出来**的三件事。渲染方式不在其中——`editor` 字段已删除：
/// 渲染由值探针定（见 `probe(_:)`），只有合成行例外（见 `syntheticKeys`）。
struct HierarchyPropertyOverride: Decodable {
    /// 枚举表名。写了它即表示这是个枚举（值在 KVC 边界上只剩裸 Int）。
    let enumType: String?
    /// 行标题。不写就用 key 本身——`isHidden` 比任何译文都准。
    let desc: String?
    /// 这一行给不给编辑器。**默认给**，标 `false` 的目前 40 行。
    ///
    /// 注意它回答的是「这个属性检查器页要不要提供编辑器」，**不是「属性可不可写」**：
    /// 有的行属性可写但没有合理的编辑器（`delegate`），有的行 UIKit 就没有 setter
    /// （`isKeyWindow`），两者都标 `false`。
    ///
    /// 布局输出（`frame` / `bounds` / `center` / `layer.position` / `layer.anchorPoint`）
    /// **刻意不表态**：它们的可编辑性取决于运行时（Auto Layout 管不管这一维），
    /// 由布局页自行判断，不做静态声明。
    let userEditable: Bool?
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

/// 一行的编辑入口。挂在 `HierarchyCellModel.edit` 上，nil 就是只读行。
struct HierarchyEditDescriptor {
    /// 写回时用的 key（**Swift 名**；真正的 KVC 写键由 `kvcWriteKey` 在实例上探出来）
    let key: String
    /// 用哪个编辑器。取值同渲染用的 editor：`bool` / `text` / `enum`
    let editor: String
    /// `editor == "enum"` 时给表名，选项从 `enumOptions(for:currentRawValue:)` 取
    let enumType: String?
    /// 当前值原样带着，供编辑器初始化：bool 读 `as? Bool`，enum 读 `as? Int` 当 rawValue
    let currentValue: Any?
}

// MARK: - Engine

class HierarchyPropertyEngine {

    static let shared = HierarchyPropertyEngine()

    private var types: [String: HierarchyTypeEntry] = [:]
    /// 枚举表，**有序**（顺序即 UI 顺序）。
    ///
    /// 一份数据同时伺候三个方向，不再另建派生索引：
    ///   读取   rawValue → 文案      （`enumDescription`，扫表）
    ///   写入   index    → rawValue  （`enumValue`）
    ///   编辑   [文案] + 当前下标    （`enumOptions`）
    private var enumTables: [String: [HierarchyEnumValue]] = [:]

    /// 置顶段的 key，**顺序即文案顺序**（与类链无关）。
    ///
    /// 就这一个数组：顺序要它、成员判断也要它（7 条，`contains` 足够），不另建 Set。
    /// 「这些 key 适用于哪些 view」不在这里——见 `resolve`。
    private var pinnedKeys: [String] = []

    /// 置顶段标题就是 JSON 的键名，不另设 title 字段
    private static let pinnedSectionTitle = "Pinned"

    /// 段标题默认由类名派生（去 `UI` 前缀 + 驼峰拆词），只有这两处对不上
    private static let sectionTitleOverrides: [String: String] = [
        "NSObject": "Object",
        "UIToolbar": "Tool Bar",
    ]

    /// 这一期实现了编辑器的 editor。**阶段闸门在代码里，不在 JSON 里** ——
    /// 一行实际可编辑 = JSON 说 `userEditable` 且这里认这个 editor。
    /// 往后每做一批编辑器就往这里加一个，JSON 一行都不用动。
    private static let editableEditors: Set<String> = ["bool", "text", "enum"]

    /// 不读 KVC、靠自己合成的行。`editor` 字段删掉之后，它们只能按 key 认。
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
            let root = try JSONDecoder().decode(HierarchyPropertiesRoot.self, from: data)
            types = root.types
            enumTables = root.enums
            // `where` 顺带去了重 —— 同一个 key 在两处列出会渲染出两行，而没有任何东西会报错
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
                .filter { !pinnedKeys.contains($0) }
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
        /// 这一行给不给编辑器。编辑功能尚未实现，当前只是把数据带到位。
        let isUserEditable: Bool
    }

    private func cellModel(for view: UIView, key: String, compact: Bool, chain: [String]) -> HierarchyCellModel? {
        guard let resolved = resolve(key: key, view: view, chain: chain),
              let model = makeCellModel(for: view, resolved: resolved, compact: compact)
        else { return nil }

        // 编辑入口只挂给**详情页**（浮层不是编辑器），且要过两道闸门：
        // JSON 的 userEditable，以及这一期实现了编辑器没有。
        if !compact, resolved.isUserEditable, Self.editableEditors.contains(resolved.editor) {
            model.edit = HierarchyEditDescriptor(key: key,
                                                 editor: resolved.editor,
                                                 enumType: resolved.enumType,
                                                 currentValue: resolved.value)
        }
        return model
    }

    /// 定下这个 key 在这个 view 上用哪个 editor、值是什么；不适用则返回 nil。
    ///
    /// 适用性：置顶段命中（且来源类在链上）算适用；否则沿类链**父类在前**找第一个
    /// 声明该 key 的类。editor 的优先级是 **覆盖 > 探针**：覆盖写了 `editor` 就用它，
    /// 只写了 `enumType` 就按枚举处理，都没有才看值的形状。
    private func resolve(key: String, view: UIView, chain: [String]) -> ResolvedProperty? {
        // 覆盖只可能来自 `types` —— 置顶段的 key 已经被从那里抽走了，不会有条目。
        var override: HierarchyPropertyOverride?
        if !pinnedKeys.contains(key) {
            // 类链父类在前，第一个声明该 key 的类说了算
            guard let className = chain.first(where: { types[$0]?.properties.contains(key) == true })
            else { return nil }        // 类链上没有这个 key → 这个属性不适用（`textColor` 之于 UIView）
            override = types[className]?.overrides?[key]
        }
        // 置顶段的 key 走到这里时 override 恒为 nil。它适用于哪些 view **不由 JSON 说**，
        // 由实例说了算 —— 下面的取值检查就是那个「说了算」的地方：读不出来就不占行。
        // 于是 `Pinned` 的 `group` 对引擎完全无用，只剩下给人读。

        let isUserEditable = override?.userEditable ?? true

        // 合成行不读 KVC：它们要的是类型名或地址，没有「值」可探
        if let editor = Self.syntheticKeys[key] {
            return ResolvedProperty(key: key, editor: editor, enumType: nil,
                                    desc: override?.desc, value: nil, isUserEditable: isUserEditable)
        }

        // 读不出值的字段直接不占行——`textColor` 之于 UIView、`backgroundColor` 为 nil
        guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

        // editor 只剩两条路：有枚举表名就是枚举，否则看值的形状
        let editor = override?.enumType != nil ? "enum" : probe(value)

        return ResolvedProperty(key: key, editor: editor, enumType: override?.enumType,
                                desc: override?.desc, value: value, isUserEditable: isUserEditable)
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

    // MARK: - Enum Options

    /// 枚举行的选项：**有序文案** + 当前下标。
    ///
    /// `enums` 本来就是有序数组（顺序即 UI 顺序），这里直接用，不需要另外维护一份。
    func enumOptions(for enumType: String, currentRawValue: Int) -> (names: [String], currentIndex: Int?) {
        guard let table = enumTables[enumType] else { return ([], nil) }
        return (table.map(\.name), table.firstIndex { $0.value == currentRawValue })
    }

    /// 第 `index` 个选项对应的 rawValue。
    ///
    /// **取表里记的 value，不是下标**：`activityIndicatorViewStyle` 是 `[0, 1, 100, 101]`，
    /// 原版 `weakSelf.accessoryType = index` 在这张表上会写进 2 / 3 这种不存在的值。
    func enumValue(for enumType: String, at index: Int) -> Int? {
        guard let table = enumTables[enumType], table.indices.contains(index) else { return nil }
        return table[index].value
    }

    // MARK: - Write Path

    /// 把新值写回属性。返回是否真的写进去了。
    ///
    /// **失败原因不穷举成枚举**——每一步自己 print 具体原因，调用方只要一个 Bool，
    /// 拿到 false 就重载这一行让 UI 回到真实状态。
    ///
    /// 只支持**点号路径之外**的属性：P1 的三个 editor（bool / text / enum）一个点号路径都没有，
    /// 而逐段确认 setter 要多写二十行。等布局页要写 `layer.position` 时再说。
    @discardableResult
    func write(_ newValue: Any, forKey key: String, to view: UIView) -> Bool {
        guard let resolved = resolve(key: key, view: view, chain: classChain(view)),
              resolved.isUserEditable, let oldValue = resolved.value else {
            print("[Hierarchy] \(key)：这一行不给编辑器")
            return false
        }
        guard !key.contains(".") else {
            print("[Hierarchy] \(key)：点号路径这一页不写")
            return false
        }
        guard let writeKey = kvcWriteKey(for: key, on: view) else { return false }
        guard isCompatible(newValue, with: oldValue) else {
            print("[Hierarchy] \(key)：\(type(of: newValue)) 替代不了 \(type(of: oldValue))")
            return false
        }

        view.setValue(newValue, forKey: writeKey)

        // 让业务页面重算布局。**不按属性分支**——isHidden 在 stack 里同样要重算，
        // 逐个判断的收益远小于维护成本。
        // layoutIfNeeded 调在 **window** 上：只调 view 会得到「尺寸是新的、位置还是旧的」半更新树，
        // 而下面的回读会被这个中间态误导。
        view.setNeedsLayout()
        view.invalidateIntrinsicContentSize()
        view.window?.layoutIfNeeded()

        // 回读：写进去了 ≠ 站住了。Auto Layout 或业务自己的数据流可能已经改回去。
        // 用**原 key** 回读——读写键可能不同名，但两个名字读都认。
        guard let landed = safeValue(forKeyPath: key, on: view), landedEquals(landed, newValue) else {
            print("[Hierarchy] \(key)：写进去了但被改回 —— 大概率由 Auto Layout 或业务逻辑管着")
            return false
        }
        return true
    }

    /// 从一个 **Swift 属性名**推出它在 KVC 里的写键候选，按可能性排序。
    ///
    /// 两套命名要分开看（实测过）：
    ///
    ///     Swift 自己声明的 `@objc var isFlag`       → 属性名就是 isFlag
    ///     ObjC 导入的 `hidden`（Swift 名 isHidden） → 属性名是 hidden
    ///
    /// 后者是 UIKit 的常态：头文件写 `@property(nonatomic,getter=isHidden) BOOL hidden;`，
    /// Swift 导入时把**属性名换成了 getter 名**，于是我们的 JSON 里存的是 `isHidden`。
    /// 查过 iOS SDK 的 441 个 UIKit 头文件：我们这批 key 里的"特殊 setter"共 14 个唯一 key，
    /// **全部**是这一种变换，没有第三种。
    ///
    /// 列成数组是为了**看得见**：真碰到规则外的 setter，失败时 print 出来就能定位。
    private static func writeKeyCandidates(for propertyName: String) -> [String] {
        var candidates = [propertyName]
        if propertyName.hasPrefix("is"), propertyName.count > 2 {
            let stripped = propertyName.dropFirst(2)
            candidates.append(stripped.prefix(1).lowercased() + stripped.dropFirst())
        }
        return candidates
    }

    /// 在候选里找第一个真有 setter 的；找不到就 print 出**试过哪些写键**。
    ///
    /// 这一步是**崩溃护栏**：KVC 找不到 setter 会抛 `NSUnknownKeyException`，而 Swift
    /// 接不住 ObjC 异常——那不是"写失败"，是**崩在宿主 app 里**。所以返回 nil 时绝不调 `setValue`。
    private func kvcWriteKey(for propertyName: String, on object: NSObject) -> String? {
        let candidates = Self.writeKeyCandidates(for: propertyName)
        let setterName = { (name: String) in "set" + name.prefix(1).uppercased() + name.dropFirst() + ":" }

        if let hit = candidates.first(where: { object.responds(to: NSSelectorFromString(setterName($0))) }) {
            return hit
        }
        print("[Hierarchy] \(propertyName) 写不进去：\(type(of: object)) 没有 setter，"
            + "试过 \(candidates.map(setterName))")
        return nil
    }

    /// 新值能不能安全替代旧值。基准是**旧值的运行时形状**——我们本来就读过它。
    ///
    /// - 标量：KVC 会把 NSNumber 按 setter 的标量类型解包，给 NSNumber 就安全，
    ///   但编码要一致（BOOL `c` / NSInteger `q` / CGFloat `d`），否则 `true` 会被塞进 `tag` 变成 1
    /// - 结构体：KVC **不做转换**，`NSValue` 的编码必须逐字相同——
    ///   `{CGPoint=dd}` 写进 `CGRect` 的属性会读出垃圾
    /// - 对象：只挡"确定不兼容"的（把 UIColor 写进 NSString 属性）
    ///
    /// `NSNumber` 的分支必须在 `NSValue` 之前——它是 `NSValue` 的子类。
    private func isCompatible(_ new: Any, with old: Any) -> Bool {
        if let n = new as? NSNumber, let o = old as? NSNumber {
            return String(cString: n.objCType) == String(cString: o.objCType)
        }
        if let n = new as? NSValue, let o = old as? NSValue {
            return String(cString: n.objCType) == String(cString: o.objCType)
        }
        if let n = new as? NSObject, let o = old as? NSObject {
            // Swift String ↔ NSString 桥接后动态类型名对不上，单独放行
            if n is NSString, o is NSString { return true }
            return n.isKind(of: type(of: o)) || o.isKind(of: type(of: n))
        }
        return false
    }

    /// 回读的值是否等于刚写进去的——"改了被弹回"和"改了没生效"的**唯一区分手段**。
    /// 浮点给容差：写 0.3 读回 0.30000000000000004 不算被弹回。
    private func landedEquals(_ landed: Any, _ written: Any) -> Bool {
        if let l = landed as? NSNumber, let w = written as? NSNumber {
            return abs(l.doubleValue - w.doubleValue) < 0.0001
        }
        if let l = landed as? NSValue, let w = written as? NSValue { return l == w }
        return (landed as? NSObject)?.isEqual(written) ?? false
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
        guard let table = enumTables[enumType] else { return "\(rawValue)" }
        return table.first { $0.value == rawValue }?.name ?? "\(rawValue)"
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
