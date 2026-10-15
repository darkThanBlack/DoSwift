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

/// 折成有序表之后的一条。读取 / 写入 / 编辑都吃它。
struct HierarchyEnumValue {
    let value: Int
    let name: String
}

/// 一个属性值的**类型 + 值本身**。
///
/// `probe(_:)` 从 KVC 拿到的 `Any` 判出它，此后渲染和回写都走它 —— 类型判定只做一次。
///
/// 为什么是枚举而不是 `Any` + 一堆 `as?`：上层 switch 它是**穷尽**的（编译器强制列全），
/// 而字符串分派会被 `default` 悄悄吞掉（这个引擎原来就是这么写的）。
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
    /// 裸 Int + 表名 + **已查好的文案**。
    ///
    /// 值在 KVC 边界上只剩裸 Int，**类型只能由 JSON 的 `enumType` 声明**——
    /// 这是探针唯一猜不出来的情况（`int` 和枚举同形）。文案在 resolve 时查表得到，
    /// 这样显示不必再回引擎拿表；表名留着给回写用。
    case enumValue(raw: Int, table: String, name: String)
    /// 探针不认识的值：原样 dump
    case unknown(Any)

    // MARK: 探针

    /// 值 → 类型。
    ///
    /// **两条路**：对象靠 `is` 判类；标量和结构体靠 `objCType` 编码串 ——
    /// 后者不能换成 `as?`，因为 KVC 把标量装箱成 `NSNumber`，`as? Bool` 是**值相关**的
    /// （实测对 `CGFloat(1.0)` 返回 true、对 `Int(2)` 返回 nil）。
    ///
    /// 顺序要紧：`NSNumber` 必须排在 `NSValue` 之前（它是子类）。
    static func probe(_ value: Any) -> ValueKind {
        switch value {
        case is UIColor: return .color(value as! UIColor)

        case let number as NSNumber:
            switch String(cString: number.objCType) {
            case "c", "C", "B": return .bool(number.boolValue)
            case "d", "f":      return .double(number.doubleValue)
            default:            return .int(number.intValue)
            }

        case let box as NSValue:
            // 取包含而非全等：结构体编码在 32/64 位、float/double 下写法不同
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

    // MARK: 交给 KVC 写回的值

    /// 写回时交给 KVC 的装箱值。形状由这个 case 自己决定 —— 读它的时候是什么类型，写回去就是什么类型。
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
    /// 置顶段。整块删掉也能跑，删了就只剩按类链分的段。
    let pinned: [HierarchyPinnedGroup]?
    let types: [String: HierarchyTypeEntry]
    /// 表名 = UIKit 的类型名；值 = Swift 的 case 字面量。
    let enums: [String: [String: String]]

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
    /// JSON 里的 key（**Swift 名**）
    let key: String
    /// **类型 + 当前值**。UI 按它选编辑器，回写也按它比对 —— 中途不再猜类型。
    let kind: ValueKind
    /// 实例上探出来的 KVC 写键。能走到这里就必然非 nil（第三道闸门刚验过）
    let writeKey: String
}

// MARK: - Engine

class HierarchyPropertyEngine {

    static let shared = HierarchyPropertyEngine()

    private var types: [String: HierarchyTypeEntry] = [:]
    /// 枚举表，**有序**（顺序即 UI 顺序）。
    ///
    /// 一份数据同时伺候三个方向，不再另建派生索引：
    ///   读取   rawValue → 文案      （`enumName`，扫表）
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
            // 值就是 JSON 的 key，**显示顺序按值升序排**出来。
            // JSON 对象的键序不可靠（`JSONSerialization` / `JSONDecoder` 都不保序），
            // 所以顺序必须算，不能指望文件里的书写顺序。
            enumTables = root.enums.mapValues { table -> [HierarchyEnumValue] in
                table.compactMap { key, name in
                    Int(key).map { HierarchyEnumValue(value: $0, name: name) }
                }
                .sorted { $0.value < $1.value }
            }
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

        let pinnedRows = pinnedKeys.compactMap { cellModel(for: view, key: $0, chain: chain) }
        if !pinnedRows.isEmpty {
            result.append(HierarchyCategoryModel(title: Self.pinnedSectionTitle, items: pinnedRows))
        }

        for className in chain {
            guard let entry = types[className] else { continue }
            let rows = entry.properties
                .filter { !pinnedKeys.contains($0) }
                .compactMap { cellModel(for: view, key: $0, chain: chain) }
            if !rows.isEmpty {
                // 段标题就是类名本身，不翻译：`UIView` 比 "View" 更没有歧义
                result.append(HierarchyCategoryModel(title: className, items: rows))
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
    func cellModel(for view: UIView, key: String) -> HierarchyCellModel? {
        return cellModel(for: view, key: key, chain: classChain(view))
    }

    // MARK: - Key Resolution

    /// 一个字段解析完的样子。**类型判定在这里做完，之后一路带着走。**
    private struct ResolvedProperty {
        let key: String
        /// 合成行（`class` / `address` / `layer.class`）的构造方式；非合成行为 nil
        let synthetic: String?
        /// 值的类型 + 值本身。合成行没有值，这里是 nil
        let kind: ValueKind?
        let desc: String?
        /// 这一行给不给编辑器（JSON 政策）
        let isUserEditable: Bool
    }

    private func cellModel(for view: UIView, key: String, chain: [String]) -> HierarchyCellModel? {
        guard let resolved = resolve(key: key, view: view, chain: chain),
              let model = makeCellModel(for: view, resolved: resolved)
        else { return nil }

        // 编辑入口三道闸门，缺一不可：
        //   ① JSON 说 `userEditable`（政策：这一行**该不该**给编辑器）
        //   ② `canEdit(kind)`   （阶段：这一期**做没做**这个类型的解析）
        //   ③ 实例上真有 setter（技术：探测，不是声明）
        // 第三道以前不存在，所以 22 行"只读 API"不得不写死在 JSON 里；现在它们可推。
        // 浮层拿到的模型也带 `edit`，但它自己不读这个字段（浮层是只读的）。
        if resolved.isUserEditable, let kind = resolved.kind,
           canEdit(kind), let writeKey = kvcWriteKey(for: key, on: view) {
            model.edit = HierarchyEditDescriptor(key: key, kind: kind, writeKey: writeKey)
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
        if let synthetic = Self.syntheticKeys[key] {
            return ResolvedProperty(key: key, synthetic: synthetic, kind: nil,
                                    desc: override?.desc, isUserEditable: isUserEditable)
        }

        // 读不出值的字段直接不占行——`textColor` 之于 UIView、`backgroundColor` 为 nil
        guard let value = safeValue(forKeyPath: key, on: view) else { return nil }

        // 类型在这里定死。枚举由 JSON 声明（探针分不出它和 int），其余交给探针
        let kind: ValueKind
        if let table = override?.enumType {
            let raw = (value as? Int) ?? (value as? NSNumber)?.intValue ?? 0
            kind = .enumValue(raw: raw, table: table, name: enumName(table, raw))
        } else {
            kind = ValueKind.probe(value)
        }

        return ResolvedProperty(key: key, synthetic: nil, kind: kind,
                                desc: override?.desc, isUserEditable: isUserEditable)
    }

    // MARK: - Per-Item Cell Building

    private func makeCellModel(for view: UIView, resolved: ResolvedProperty) -> HierarchyCellModel? {
        let title = resolved.desc ?? resolved.key

        // 合成行：不读值，从 view 自己造。它是全程唯一一行带分隔线的
        if let synthetic = resolved.synthetic {
            return cell(title, syntheticText(synthetic, view), separator: synthetic == "layerClass")
        }

        guard let kind = resolved.kind else { return nil }

        return cell(title, displayText(of: kind), separator: false)
    }

    /// 造一行。分隔线的显隐是**逐行**的（沿用本仓库现状，不是这次改动引入的规则）。
    private func cell(_ title: String?, _ detail: String?, separator: Bool) -> HierarchyCellModel {
        let model = HierarchyCellModel(title: title, detailTitle: detail)
        if !separator {
            model.noneInsets()
        }
        return model
    }

    // MARK: - 值的两个方向：显示 ⇄ 解析
    //
    // 两个 switch **并排、case 顺序一致**：看某一种类型的显示时，它的解析就在下面几行。
    // 两侧都穷尽（编译器强制列全），所以加一个类型时两处都会报错、都会被填上。

    /// 值 → 显示字符串
    /// 同一个值的字符串形态 —— 列表那一行和卡片底栏的「当前」**都出自这里**，
    /// 所以是 internal 而不是 private。
    func displayText(of kind: ValueKind) -> String {
        switch kind {
        case .bool(let v):          return v ? "true" : "false"
        case .int(let v):           return "\(v)"
        case .double(let v):        return HierarchyFormatterTool.format(NSNumber(value: v))
        case .text(let v):          return formatText(v)
        case .color(let v):         return v.hierarchy_description
        case .font(let v):          return fontDescription(v)
        case .image(let v):         return formatImage(v)
        case .date(let v):          return HierarchyFormatterTool.string(from: v) ?? "<null>"
        case .attributedText:       return "Attributed Text"
        case .frame(let v):         return HierarchyFormatterTool.string(from: v)
        case .point(let v):         return pointDescription(v)
        case .size(let v):          return sizeDescription(v)
        case .insets(let v):        return insetsDescription(v)
        case .enumValue(_, _, let name): return name
        case .unknown(let v):       return formatObject(v)
        }
    }

    /// 显示字符串 → 同类型的新值。`nil` = 输入不合法。
    /// 未实现的类型也返回 nil —— 靠 `canEdit` 那道闸门区分"没做"和"打错了"。
    /// 对详情页可见：文本类编辑器拿到输入后先过它。
    func parsed(_ string: String, into kind: ValueKind) -> ValueKind? {
        switch kind {
        case .bool:
            switch string.lowercased() {
            case "true", "1", "yes", "on":  return .bool(true)
            case "false", "0", "no", "off": return .bool(false)
            default:                        return nil
            }

        case .text:
            return .text(string)                        // 无需解析

        case .enumValue(_, let table, _):
            // 文案（"center"）或裸值（"1"）都收
            if let raw = Int(string) { return .enumValue(raw: raw, table: table, name: enumName(table, raw)) }
            guard let hit = enumTables[table]?.first(where: { $0.name.caseInsensitiveCompare(string) == .orderedSame })
            else { return nil }
            return .enumValue(raw: hit.value, table: table, name: hit.name)

        case .int:
            return Int(string).map(ValueKind.int)

        case .double:
            return Double(string).map(ValueKind.double)

        case .color:
            return UIColor.hierarchy_color(from: string).map(ValueKind.color)

        case .font(let current):
            // 只改字号 —— 原版也是（`[font fontWithSize:]`）。
            // 字体族是另一个轴，要走系统字体面板（`UIFontPickerViewController`），另说
            return Double(string).map { ValueKind.font(current.withSize(CGFloat($0))) }

        case .date:
            return HierarchyFormatterTool.date(from: string).map(ValueKind.date)

        case .size, .insets:
            // **不走字符串**：这两种类型在 UI 上是数字格（N 个数字各自成格），
            // 合成结构体直接交给 `write`，不经过"拼成 `{0, 2}` 再解析回来"这一圈。
            return nil

        case .frame, .point:
            // **布局输出**：改了就弹回（Auto Layout 或父视图会盖掉），不在这一页的职责里。
            // 显示照旧（上面的 displayText 有），但不给编辑器 —— 交给另起的布局页。
            return nil

        case .image, .attributedText:
            // 能写，但 JSON 上这 12 行是 `userEditable: false`，所以不会有行走到这里。
            // 想做的时候（`UIImage(systemName:)` / 整段替换）再补，闸门在 JSON 那一侧
            return nil

        case .unknown:
            return nil                                  // 探针都不认识的类型，不给编辑器
        }
    }

    /// 这一期实现了哪些类型的解析 —— **编辑器的阶段闸门就是它**。
    ///
    /// 单独一个 switch，而不是"让 parsed 拿空串试一次"：这里问的是"有没有做"，
    /// 和"这个输入对不对"是两件事。
    private func canEdit(_ kind: ValueKind) -> Bool {
        switch kind {
        case .bool, .text, .int, .double, .enumValue,
             .color, .font, .date, .size, .insets:     return true
        case .image, .attributedText:
            // `parsed` 对这两个返回 nil，所以这里必须也是 false —— 否则那行会显示编辑器，
            // 而任何输入都失败。等补了它们的 parsed，两处一起改。
            // （它们那 12 行本来就全是 userEditable: false，所以现在也没有行会走到这）
            return false
        case .frame, .point:
            return false                                // 布局输出，交给另起的布局页
        case .unknown:
            return false                                // 探针不认识的类型
        }
    }

    /// 合成行（`class` / `address` / `layer.class`）的文本
    private func syntheticText(_ synthetic: String, _ view: UIView) -> String {
        switch synthetic {
        case "className":  return String(describing: type(of: view))
        case "layerClass": return String(describing: type(of: view.layer))
        default:           return String(format: "%p", Int(bitPattern: Unmanaged.passUnretained(view).toOpaque()))
        }
    }

    /// rawValue → 文案。查不到回落到裸数字（枚举表不全时的表现）
    private func enumName(_ table: String, _ rawValue: Int) -> String {
        enumTables[table]?.first { $0.value == rawValue }?.name ?? "\(rawValue)"
    }

    // MARK: - Enum Options

    /// 枚举行的选项：**有序文案** + 当前下标。
    ///
    /// `enums` 本来就是有序数组（顺序即 UI 顺序），这里直接用，不需要另外维护一份。
    /// `rawValues` 一并交出来：列表每一行右侧要显示它，而"名字"和"值"必须来自同一张表
    /// —— 分开两次查，中间要是表被换了就对不上。
    func enumOptions(for enumType: String, currentRawValue: Int)
        -> (names: [String], rawValues: [Int], currentIndex: Int?) {
        guard let table = enumTables[enumType] else { return ([], [], nil) }
        return (table.map(\.name), table.map(\.value), table.firstIndex { $0.value == currentRawValue })
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
    func write(_ newValue: ValueKind, forKey key: String, to view: UIView) {
        guard let resolved = resolve(key: key, view: view, chain: classChain(view)),
              resolved.isUserEditable, let oldKind = resolved.kind else {
            print("[Hierarchy] \(key)：这一行不给编辑器")
            return
        }
        guard canEdit(oldKind) else {
            print("[Hierarchy] \(key)：这个类型的编辑器还没做")
            return
        }
        guard !key.contains(".") else {
            print("[Hierarchy] \(key)：点号路径这一页不写")
            return
        }
        guard let writeKey = kvcWriteKey(for: key, on: view) else { return }

        // **不在这里判"能不能代替"**：`kind` 是刚从这一行读出来的，形状天然对得上；
        // 再拦一道只会误伤 —— `Float` 属性（`UISlider.value` / `UIProgressView.progress`）
        // 读出来是 `'f'`、我们装箱成 `'d'`，KVC 自己能按属性的真实编码解包，是我们挡下的。
        view.setValue(newValue.boxed, forKey: writeKey)

        // 让业务页面重算布局。**不按属性分支**——isHidden 在 stack 里同样要重算，
        // 逐个判断的收益远小于维护成本。
        // layoutIfNeeded 调在 **window** 上：只调 view 会得到「尺寸是新的、位置还是旧的」半更新树，
        // 而下面的回读会被这个中间态误导。
        view.setNeedsLayout()
        view.invalidateIntrinsicContentSize()
        view.window?.layoutIfNeeded()

        // **不做回读校验**：写完把列表重读一遍，那一行自己会显示真实值 —— 那就是验证，
        // 而且比我们判得准。自己判的代价是假阴性（`landedEquals` 的绝对容差会让
        // `1_234_567.89` 这种大数值在 `Float` 属性上被冤判成"被弹回"）。
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

    // MARK: - Formatters

    /// 字体：**一行**，族名 + 字号。
    ///
    /// `UIFont.description` 是三行的 `<UICTFont: 0x…> font-family: …; font-size: 17.00pt`，
    /// 有用的只有字号和族名两项，还都得从行中间挑。系统字体的族名是 `.AppleSystemUIFont`
    /// 这种点开头的内部名，直接显示不如叫它 `System`。
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
        return "X: \(HierarchyFormatterTool.format(NSNumber(value: Double(point.x))))   Y: \(HierarchyFormatterTool.format(NSNumber(value: Double(point.y))))"
    }

    func sizeDescription(_ size: CGSize) -> String {
        return "W: \(HierarchyFormatterTool.format(NSNumber(value: Double(size.width))))   H: \(HierarchyFormatterTool.format(NSNumber(value: Double(size.height))))"
    }

    /// 四个分量全列 —— 原版只给 top/bottom（当年浮层一行放不下），但编辑面板是四个格子，
    /// 列表里少了两个分量，就等于让人蒙着眼改 left/right。
    func insetsDescription(_ insets: UIEdgeInsets) -> String {
        let f = { (v: CGFloat) in HierarchyFormatterTool.format(NSNumber(value: Double(v))) }
        return "T: \(f(insets.top))   L: \(f(insets.left))   B: \(f(insets.bottom))   R: \(f(insets.right))"
    }
}
