//
//  UserDefaultsSnapshot.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    struct UserDefaultsSnapshot {

        struct Domain {
            let name: String
            let title: String
            let items: [Item]
        }

        struct Item {

            let key: String

            let value: Any

            var summary: String {
                if let data = value as? Data {
                    return DO.Text.UserDefaults.dataSummary(data.count)
                }

                let clipped = String(String(describing: value).prefix(150))
                return clipped.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            }

            var fullText: String {
                String(describing: value)
            }
        }

        let domains: [Domain]

        static func capture(_ defaults: UserDefaults = .standard) -> DO.UserDefaultsSnapshot {
            let appName = Bundle.main.bundleIdentifier ?? ""

            let volatileNames = defaults.volatileDomainNames
            func volatile(_ name: String) -> [String: Any] {
                guard volatileNames.contains(name) else { return [:] }
                return defaults.volatileDomain(forName: name)
            }

            let searchList: [(name: String, title: String, values: [String: Any])] = [
                (UserDefaults.argumentDomain, UserDefaults.argumentDomain, volatile(UserDefaults.argumentDomain)),
                (appName, DO.Text.UserDefaults.appDomain, defaults.persistentDomain(forName: appName) ?? [:]),
                (UserDefaults.globalDomain, UserDefaults.globalDomain, defaults.persistentDomain(forName: UserDefaults.globalDomain) ?? [:]),
                (UserDefaults.registrationDomain, UserDefaults.registrationDomain, volatile(UserDefaults.registrationDomain)),
            ]

            var grouped: [String: [Item]] = [:]
            var unattributed: [Item] = []

            for (key, value) in defaults.dictionaryRepresentation() {
                let item = Item(key: key, value: value)
                if let owner = searchList.first(where: { $0.values[key] != nil }) {
                    grouped[owner.name, default: []].append(item)
                } else {
                    unattributed.append(item)
                }
            }

            let displayOrder = searchList.filter { $0.name == appName } + searchList.filter { $0.name != appName }

            var domains: [Domain] = []
            for (name, title, _) in displayOrder {
                guard let items = grouped[name], !items.isEmpty else { continue }
                domains.append(Domain(name: name, title: title, items: sorted(items)))
            }
            if !unattributed.isEmpty {
                domains.append(Domain(name: "", title: DO.Text.UserDefaults.otherDomains, items: sorted(unattributed)))
            }

            return DO.UserDefaultsSnapshot(domains: domains)
        }

        private static func sorted(_ items: [Item]) -> [Item] {
            items.sorted { $0.key.lowercased() < $1.key.lowercased() }
        }

        func filtered(by keyword: String) -> DO.UserDefaultsSnapshot {
            let trimmed = keyword.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return self }

            let lowered = trimmed.lowercased()
            let domains = domains.compactMap { domain -> Domain? in
                let items = domain.items.filter { $0.key.lowercased().contains(lowered) }
                return items.isEmpty ? nil : Domain(name: domain.name, title: domain.title, items: items)
            }
            return DO.UserDefaultsSnapshot(domains: domains)
        }
    }
}
