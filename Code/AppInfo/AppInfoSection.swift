//
//  AppInfoSection.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

extension DO {

    public typealias AppInfoRow = (title: String, value: String)

    public typealias AppInfoSection = (title: String, rows: [DO.AppInfoRow])

    enum AppInfoSectionBuilder {

        static func make(_ title: String, _ rows: [(title: String, value: String?)]) -> DO.AppInfoSection? {
            let visible = rows.compactMap { row -> DO.AppInfoRow? in
                guard let value = row.value else { return nil }
                return (title: row.title, value: value)
            }
            return visible.isEmpty ? nil : (title: title, rows: visible)
        }
    }
}
