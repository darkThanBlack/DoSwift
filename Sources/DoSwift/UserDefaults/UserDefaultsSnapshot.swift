//
//  UserDefaultsSnapshot.swift
//  DoSwift
//

import Foundation

/// 一次读取 UserDefaults 的结果：按**来源域**分好组的键值。
///
/// 整个工具里只有这一处懂 UserDefaults 的「域」，别处只当它是一份分组数据。
///
/// 为什么必须按域分组：`dictionaryRepresentation()` 返回的是**搜索列表的合成快照**
/// （`NSUserDefaults.h:143`：「a composite snapshot of the values in the receiver's search list」），
/// 里面除了 app 自己写的，还有启动参数、注册默认值、系统全局域的内容。同一个 key
/// 可能只存在于某个下层域里，所以「这个 key 是哪来的」只能**当场问每个域**——
/// 一张写死的名单必然过期：域里有什么随系统版本、设备、配置描述文件变。
struct UserDefaultsSnapshot {

    /// 一个域。`name` 是域标识（应用域就是 bundle id），`title` 是分组标题。
    struct Domain {
        let name: String
        let title: String
        let items: [Item]
    }

    /// 一个键值
    struct Item {

        let key: String

        /// 值的原文。**不做任何解析**——要看的就是「UserDefaults 里到底存了什么」。
        let value: Any

        /// 列表行的单行摘要。全文在详情页里，这里只要「一眼认得出是哪一条」。
        ///
        /// 有两件事必须在这里做，不能把 `String(describing:)` 直接丢给单行 label：
        /// - **折成一行**：经 `UserDefaults` 回来的数组 / 字典是 `__NSArrayI` / `__NSDictionaryI`
        ///   （实测），印出来是**带换行的老式格式**（`"(\n    a,\n    b\n)"`）——单行 label
        ///   只会显示出开头那个 `(` 或 `{`。
        /// - **截断**：先取原文前 150 个字符。一个 2000 元素的字典印出来 4.8 万字符，
        ///   而单行 label 真正显示得下的不到 40 个 —— 后面那些连量都不必去量。
        ///
        /// `Data` 单独给一条纯粹是为了好看：`String(describing:)` 对它给的是 hex dump
        /// （`{length = 307200, bytes = 0xabab…}`），报长度清楚得多。
        /// 顺带记一笔实测：**这一步不是为了省时间** —— Swift `Data` 印 `N bytes`、
        /// 经 `UserDefaults` 回来的 `__NSSwiftData` 印截断的 hex，两者都是 O(1)
        /// （4MB 与 4KB 都是 0.002 ms）。真正贵的是数组 / 字典，与元素数成正比。
        var summary: String {
            if let data = value as? Data {
                return "Data · \(data.count) bytes"
            }

            // 先按**原文字符数**截 150，再折成一整行：截断的位置和折行无关，
            // 顺序反过来的话，截断就是在折行后的长度上算，含义不清
            let clipped = String(String(describing: value).prefix(150))
            return clipped.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }

        /// 详情页的全文：原文照搬，换行保留（放在可滚动的 `UITextView` 里，多行才是最好读的形态）。
        var fullText: String {
            String(describing: value)
        }
    }

    let domains: [Domain]

    // MARK: - Capture

    /// 读一次 `UserDefaults`
    static func capture(_ defaults: UserDefaults = .standard) -> UserDefaultsSnapshot {
        let appName = Bundle.main.bundleIdentifier ?? ""

        // volatile 域（启动参数 / 注册默认值）只能按系统给的名单读：
        // 域名不在名单里时 `volatileDomain(forName:)` 的行为没有保证（所以不硬编码域名，
        // 也不假定一定存在）。
        let volatileNames = defaults.volatileDomainNames
        func volatile(_ name: String) -> [String: Any] {
            guard volatileNames.contains(name) else { return [:] }
            return defaults.volatileDomain(forName: name)
        }

        // 搜索列表的顺序（`NSUserDefaults.h:12-17` 的注释）：
        // 启动参数域 → 应用域 → 附加 suite → 全局域 → 注册默认值域。
        // 「这个 key 是哪来的」= 按这个顺序**第一个命中**它的域。
        let searchList: [(name: String, title: String, values: [String: Any])] = [
            (UserDefaults.argumentDomain, UserDefaults.argumentDomain, volatile(UserDefaults.argumentDomain)),
            (appName, "App", defaults.persistentDomain(forName: appName) ?? [:]),
            (UserDefaults.globalDomain, UserDefaults.globalDomain, defaults.persistentDomain(forName: UserDefaults.globalDomain) ?? [:]),
            (UserDefaults.registrationDomain, UserDefaults.registrationDomain, volatile(UserDefaults.registrationDomain)),
        ]

        // 以 `dictionaryRepresentation()` 为准来枚举「存在哪些 key」——它就是
        // 「读任何一个 key 会拿到什么」的合成快照。按它枚举、按域归属，两边都不猜。
        var grouped: [String: [Item]] = [:]
        var unattributed: [Item] = []

        for (key, value) in defaults.dictionaryRepresentation() {
            let item = Item(key: key, value: value)
            if let owner = searchList.first(where: { $0.values[key] != nil }) {
                grouped[owner.name, default: []].append(item)
            } else {
                // 认不出来源的（例如 `addSuiteNamed:` 加进来、名字无法枚举的 suite 域）也照列：
                // 这是个调试工具，藏数据比多一个分组糟糕得多。
                unattributed.append(item)
            }
        }

        // 显示顺序：App 置顶（先看自己写的），其余按搜索列表顺序；空域不出分组。
        let displayOrder = searchList.filter { $0.name == appName } + searchList.filter { $0.name != appName }

        var domains: [Domain] = []
        for (name, title, _) in displayOrder {
            guard let items = grouped[name], !items.isEmpty else { continue }
            domains.append(Domain(name: name, title: title, items: sorted(items)))
        }
        if !unattributed.isEmpty {
            domains.append(Domain(name: "", title: "Other Domains", items: sorted(unattributed)))
        }

        return UserDefaultsSnapshot(domains: domains)
    }

    /// 分组内按 key 排序。大小写不敏感：`kMenuHandleFrameKey` 和 `AppleLanguages`
    /// 要能挨着按字母看，而不是所有大写开头的挤在一起。
    private static func sorted(_ items: [Item]) -> [Item] {
        items.sorted { $0.key.lowercased() < $1.key.lowercased() }
    }

    // MARK: - Filter

    /// 按 key 过滤（大小写不敏感）。空关键字返回自身。
    ///
    /// **只按 key、不碰值**：一是要找的通常就是 key；二是搜值意味着每敲一个键都对每个
    /// value 做一遍 `String(describing:)`，而这份开销随值的大小走（实测 2000 键的字典
    /// 印一次 2 ms）——按键重来一遍不划算。真要搜值，得先在 `capture()` 里预生成小写
    /// 搜索串，把这份开销从「每敲一键」挪到「每读一次」。
    func filtered(by keyword: String) -> UserDefaultsSnapshot {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return self }

        let lowered = trimmed.lowercased()
        let domains = domains.compactMap { domain -> Domain? in
            let items = domain.items.filter { $0.key.lowercased().contains(lowered) }
            return items.isEmpty ? nil : Domain(name: domain.name, title: domain.title, items: items)
        }
        return UserDefaultsSnapshot(domains: domains)
    }
}
