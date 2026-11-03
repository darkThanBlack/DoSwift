//
//  TrendDisplayStyle.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

extension DO {

    enum TrendDisplayStyle: String, CaseIterable {

        case line

        case text

        var title: String {
            switch self {
            case .line: return DO.Text.Trend.lineChart
            case .text: return DO.Text.Trend.singleLineText
            }
        }
    }
}
