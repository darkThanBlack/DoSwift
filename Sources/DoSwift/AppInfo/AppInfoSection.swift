//
//  AppInfoSection.swift
//  DoSwift
//

/// 一页数据里的一行：标题 + 值。
///
/// **只有字符串**——没有 cell、没有点击动作。这一层只回答「有哪些字段、值是多少」，
/// 「画成哪种 cell、点一下做什么」是页面自己的事。
public typealias DoSwiftAppInfoRow = (title: String, value: String)

/// 一组：组标题 + 若干行。顺序即展示顺序。
public typealias DoSwiftAppInfoSection = (title: String, rows: [DoSwiftAppInfoRow])

/// 拼组的唯一工具。
///
/// **值为 nil 的行不出现**：取不到就不占行，所以「iOS 16 起设备名恒等于机型号」这类
/// 条件不必写成 `if`，把值留成 nil 就够了。
enum AppInfoSection {

    static func make(_ title: String, _ rows: [(title: String, value: String?)]) -> DoSwiftAppInfoSection? {
        let visible = rows.compactMap { row -> DoSwiftAppInfoRow? in
            guard let value = row.value else { return nil }
            return (title: row.title, value: value)
        }
        return visible.isEmpty ? nil : (title: title, rows: visible)
    }
}
