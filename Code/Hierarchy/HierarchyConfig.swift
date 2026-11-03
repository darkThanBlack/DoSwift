//
//  HierarchyConfig.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/10
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    struct HierarchyConfig: Codable, Equatable {

        enum Visibility: String, Codable, CaseIterable {

            case never
            case whileDragging
            case always

            var title: String {
                switch self {
                case .never:         return DO.Text.Hierarchy.never
                case .whileDragging: return DO.Text.Hierarchy.whileDragging
                case .always:        return DO.Text.Hierarchy.always
                }
            }

            func isVisible(whileDragging isDragging: Bool) -> Bool {
                switch self {
                case .never:         return false
                case .whileDragging: return isDragging
                case .always:        return true
                }
            }
        }

        var isColorPickEnabled: Bool = true

        var loupeVisibility: Visibility = .whileDragging

        var isAlignRulerEnabled: Bool = true

        var rulerVisibility: Visibility = .always

        var isIgnorePrivateClass: Bool = true

        private static let defaultsKey = "kHierarchyConfig"

        static func load() -> DO.HierarchyConfig {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let config = try? JSONDecoder().decode(DO.HierarchyConfig.self, from: data) else {
                return DO.HierarchyConfig()
            }
            return config
        }

        func save() {
            guard let data = try? JSONEncoder().encode(self) else { return }
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }

        private enum CodingKeys: String, CodingKey {
            case isColorPickEnabled, loupeVisibility
            case isAlignRulerEnabled, rulerVisibility
            case isIgnorePrivateClass
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let fallback = DO.HierarchyConfig()

            isColorPickEnabled = try container.decodeIfPresent(Bool.self, forKey: .isColorPickEnabled)
                ?? fallback.isColorPickEnabled
            loupeVisibility = try container.decodeIfPresent(Visibility.self, forKey: .loupeVisibility)
                ?? fallback.loupeVisibility
            isAlignRulerEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAlignRulerEnabled)
                ?? fallback.isAlignRulerEnabled
            rulerVisibility = try container.decodeIfPresent(Visibility.self, forKey: .rulerVisibility)
                ?? fallback.rulerVisibility
            isIgnorePrivateClass = try container.decodeIfPresent(Bool.self, forKey: .isIgnorePrivateClass)
                ?? fallback.isIgnorePrivateClass
        }

        init() {}
    }
}
