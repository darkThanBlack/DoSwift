//
//  AppInfoDevice.swift
//  DoSwift
//

import UIKit
import Darwin

/// 「设备」组。
///
/// 上面是**存下来的值**（默认 nil，`reload()` 时赋值），下面是取值本身。
/// 取值全是读操作：不改状态、不弹窗、不请求权限、不联网。
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

    func section() -> DoSwiftAppInfoSection? {
        return AppInfoSection.make("设备", [
            ("机型", model),
            ("系统版本", systemVersion),
            ("屏幕", screen),
            ("设备名称", name),
            ("IPv4", ipv4),
            ("IPv6", ipv6),
        ])
    }

    // MARK: - 取值

    /// 机器码，如 `iPhone17,1`。
    ///
    /// 模拟器上 `uname` 给的是**宿主架构**（Apple Silicon 上是 `arm64`），没有任何意义，
    /// 所以先看 `SIMULATOR_MODEL_IDENTIFIER`——那才是被模拟的那台设备。
    private static func machineCode() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var info = utsname()
        uname(&info)
        // 定长 C 字符数组，读到第一个 0 为止；`String(decoding:)` 会拷一份，
        // 所以字符串带出闭包是安全的（裸 buffer 出了闭包就不作数了）
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    /// 「iPhone 16 Pro (iPhone17,1)」。表里没有的机型只给机器码。
    ///
    /// 两个都留着是因为用处不同：市场名给人看，机器码给 issue 和检索用。
    private static func deviceModel() -> String {
        let code = machineCode()
        guard let name = AppInfoDeviceModel.names[code] else { return code }
        return "\(name) (\(code))"
    }

    /// 「26.2 (23C54)」——系统版本 + 系统构建号（`kern.osversion`，设置「关于本机」里括号那段）。
    private static func systemVersion() -> String {
        let version = UIDevice.current.systemVersion
        guard let build = sysctlString("kern.osversion") else { return version }
        return "\(version) (\(build))"
    }

    /// 设备名。**iOS 16 起 `UIDevice.name` 就是机型号本身**（头文件原话：
    /// "Synonym for model. Prior to iOS 16, user-assigned device name"），
    /// 真名要 `com.apple.developer.device-information.user-assigned-device-name`
    /// 这个 entitlement，普通 App 申请不到。所以只在它还有信息量时才有值。
    private static func deviceName() -> String? {
        let name = UIDevice.current.name
        return name == UIDevice.current.model ? nil : name
    }

    /// 屏幕：点尺寸 · 像素尺寸 · 刷新率。
    ///
    /// 点尺寸与像素尺寸都给，是因为「放大显示」这类显示缩放模式下两者不成整数倍关系，
    /// 而**只有像素尺寸是那块屏的物理规格**。刷新率给的是这块屏的上限
    /// （ProMotion 机型 120，其余 60），不是当前帧率。
    ///
    /// 屏取自**业务窗口**那块：`UIScreen.main` 在 iOS 26 已废弃的正路是
    /// `windowScene.screen`，分屏 iPad 上也只有它答得对。后两级兜底分别给
    /// 「窗口还没上屏」和「没上 Scene 的老 App」。
    private static func screen() -> String {
        let screen = DoSwiftCore.shared.appWindow?.windowScene?.screen
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

    /// 按接口顺序挑一个地址：第一个不是链路本地的就赢；全是链路本地就退而求其次。
    ///
    /// 链路本地（`fe80::…`）每个接口上都有一个，拿去联调没有意义。
    /// 取不到不是错误——纯 IPv6 网络下就没有 IPv4 地址，返回 nil 让那一行不出现。
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

    /// 扫一遍所有已启用、非回环的接口。键是 `接口名/地址族`。
    ///
    /// 一个接口可能挂着多个地址（`en0` 上常常同时有链路本地和全局 IPv6），所以值是数组。
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
