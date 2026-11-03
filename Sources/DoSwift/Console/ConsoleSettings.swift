//
//  ConsoleSettings.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/03
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    /// The switches on the console settings page, persisted across launches.
    struct ConsoleSettings: Codable, Equatable {

        var sources: Set<DO.ConsoleLine.Source>

        var mergesSameTimestamp: Set<DO.ConsoleLine.Source>

        var includesEmptySubsystem: Bool

        private static let defaultsKey = "kConsoleSettings"

        static func load() -> DO.ConsoleSettings {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let settings = try? JSONDecoder().decode(DO.ConsoleSettings.self, from: data) else {
                return DO.ConsoleSettings()
            }
            return settings
        }

        func save() {
            guard let data = try? JSONEncoder().encode(self) else { return }
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }

        init(
            sources: Set<DO.ConsoleLine.Source> = Set(DO.ConsoleLine.Source.allCases),
            mergesSameTimestamp: Set<DO.ConsoleLine.Source> = [.standardOutput, .standardError],
            includesEmptySubsystem: Bool = true
        ) {
            self.sources = sources
            self.mergesSameTimestamp = mergesSameTimestamp
            self.includesEmptySubsystem = includesEmptySubsystem
        }

        private enum CodingKeys: String, CodingKey {
            case sources, mergesSameTimestamp, includesEmptySubsystem
        }

        /// Per-field fallback: a key added later must not reset what is already stored.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let fallback = DO.ConsoleSettings()

            sources = try container.decodeIfPresent(Set<DO.ConsoleLine.Source>.self, forKey: .sources)
                ?? fallback.sources
            mergesSameTimestamp = try container.decodeIfPresent(
                Set<DO.ConsoleLine.Source>.self, forKey: .mergesSameTimestamp
            ) ?? fallback.mergesSameTimestamp
            includesEmptySubsystem = try container.decodeIfPresent(Bool.self, forKey: .includesEmptySubsystem)
                ?? fallback.includesEmptySubsystem
        }
    }
}
