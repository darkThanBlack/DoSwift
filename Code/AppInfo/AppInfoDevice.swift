//
//  AppInfoDevice.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit
import Darwin

extension DO {

    final class AppInfoDevice {

        private(set) var model: String?
        private(set) var systemVersion: String?
        private(set) var screen: String?
        private(set) var name: String?
        private(set) var ipv4: String?
        private(set) var ipv6: String?

        func reload() {
            model = Self.deviceModel()
            systemVersion = Self.systemVersion()
            screen = Self.screen()
            name = Self.deviceName()
            ipv4 = Self.address(preferring: ["en0", "pdp_ip0"], family: AF_INET)
            ipv6 = Self.address(preferring: ["en0", "pdp_ip0"], family: AF_INET6)
        }

        func section() -> DO.AppInfoSection? {
            return DO.AppInfoSectionBuilder.make(DO.Text.AppInfo.deviceSection, [
                (DO.Text.AppInfo.rowModel, model),
                (DO.Text.AppInfo.rowSystemVersion, systemVersion),
                (DO.Text.AppInfo.rowScreen, screen),
                (DO.Text.AppInfo.rowDeviceName, name),
                ("IPv4", ipv4),
                ("IPv6", ipv6),
            ])
        }

        private static func machineCode() -> String {
            if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return simulated
            }
            var info = utsname()
            uname(&info)
            return withUnsafeBytes(of: &info.machine) { raw in
                String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
            }
        }

        private static func deviceModel() -> String {
            let code = machineCode()
            guard let name = DO.AppInfoDeviceModel.names[code] else { return code }
            return "\(name) (\(code))"
        }

        private static func systemVersion() -> String {
            let version = UIDevice.current.systemVersion
            guard let build = sysctlString("kern.osversion") else { return version }
            return "\(version) (\(build))"
        }

        private static func deviceName() -> String? {
            let name = UIDevice.current.name
            return name == UIDevice.current.model ? nil : name
        }

        private static func screen() -> String {
            let screen = DO.Core.shared.appWindow?.windowScene?.screen
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.screen
                ?? UIScreen.main

            let points = screen.bounds.size
            let pixels = screen.nativeBounds.size
            return "\(Int(points.width))×\(Int(points.height)) pt · "
                + "\(Int(pixels.width))×\(Int(pixels.height)) px · "
                + "\(screen.maximumFramesPerSecond)Hz"
        }

        private static func address(preferring interfaces: [String], family: Int32) -> String? {
            let all = interfaceAddresses()
            var linkLocal: String?
            for interface in interfaces {
                for candidate in all["\(interface)/\(family)"] ?? [] {
                    if candidate.hasPrefix("fe80:") {
                        linkLocal = linkLocal ?? candidate
                        continue
                    }
                    return candidate
                }
            }
            return linkLocal
        }

        private static func interfaceAddresses() -> [String: [String]] {
            var result: [String: [String]] = [:]

            var head: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&head) == 0, let first = head else { return result }
            defer { freeifaddrs(head) }

            for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
                let flags = Int32(pointer.pointee.ifa_flags)
                guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                      let address = pointer.pointee.ifa_addr else { continue }

                let family = Int32(address.pointee.sa_family)
                guard family == AF_INET || family == AF_INET6 else { continue }

                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let length = socklen_t(address.pointee.sa_len)
                guard getnameinfo(address, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else {
                    continue
                }

                let name = String(cString: pointer.pointee.ifa_name)
                result["\(name)/\(family)", default: []].append(String(cString: host))
            }
            return result
        }

        private static func sysctlString(_ name: String) -> String? {
            var size = 0
            guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
            var buffer = [CChar](repeating: 0, count: size)
            guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
            return String(cString: buffer)
        }
    }
}
