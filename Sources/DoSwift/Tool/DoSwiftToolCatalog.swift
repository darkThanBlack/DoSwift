//
//  DoSwiftToolCatalog.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/28.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 工具轨的默认工具目录。
///
/// 内容镜像 DoKit-iOS 的主菜单——`DoraemonManager.m` 的 `initData` 注册顺序，
/// 配合 `getDefaultPluginDataWithPluginType:` 里的标题/图标/模块表。共 37 项、5 个模块，
/// 顶层扁平、无二级菜单，与 DoKit 原版一致。
///
/// DoKit 里「Weex」与「平台工具」两个模块分别由 `DoraemonWithWeex` / `DoraemonWithDiDi`
/// 编译开关控制；这里无条件全量镜像。要裁掉就删掉对应的分组。
///
/// **图标**一律取 iOS 13（SF Symbols 1）就存在的符号，37 个逐个核对过
/// SF Symbols 的 `name_availability.plist`（`year == 2019`），且无重复。
/// 原版用的是自带切图（`doraemon_fps` 这类），后续换成切图只需改这里的符号名。
///
/// 这里**只有数据**：每个 `DoSwiftMenuItem.actionHandler` 都是 nil，
/// 行为由 `DoSwiftCore.attachDefaultActions(to:)` 按 `identifier` 挂载。
public enum DoSwiftToolCatalog {

    /// 默认的 5 个分组 / 37 项，顺序即 DoKit 的注册顺序。
    public static func defaultToolGroups() -> [DoSwiftToolGroup] {

        // MARK: 常用工具（11）

        let common = DoSwiftToolGroup(title: "常用工具", items: [
            item("app_setting",    "应用设置",      "gear"),
            item("app_info",       "App信息",       "info.circle"),
            item("sandbox",        "沙盒浏览器",    "folder"),
            item("mock_gps",       "Mock GPS",      "location"),
            item("h5",             "H5任意门",      "safari"),
            item("clean_cache",    "清理缓存",      "trash"),
            item("nslog",          "NSLog",         "doc.text"),
            item("lumberjack",     "Lumberjack",    "doc.plaintext"),
            item("db_view",        "DBView",        "archivebox"),
            item("user_defaults",  "UserDefaults",  "rectangle.grid.2x2"),
            item("js_script",      "JS脚本",        "chevron.left.slash.chevron.right"),
        ])

        // MARK: 性能检测（14）

        let performance = DoSwiftToolGroup(title: "性能检测", items: [
            item("fps",             "帧率",         "speedometer"),
            item("cpu",             "CPU",          "gauge"),
            item("memory",          "内存",         "cube.box"),
            item("network",         "网络",         "wifi"),
            item("crash",           "Crash",        "exclamationmark.triangle"),
            item("sub_thread_ui",   "子线程UI",     "rectangle.on.rectangle"),
            item("anr",             "卡顿",         "hourglass"),
            item("method_use_time", "Load耗时",     "clock"),
            item("large_image",     "大图检测",     "photo"),
            item("start_time",      "启动耗时",     "power"),
            item("memory_leak",     "内存泄漏",     "drop.triangle"),
            item("ui_profile",      "UI层级",       "square.stack.3d.up"),
            item("time_profile",    "函数耗时",     "timer"),
            item("weak_network",    "模拟弱网",     "wifi.exclamationmark"),
        ])

        // MARK: 视觉工具（5）

        let visual = DoSwiftToolGroup(title: "视觉工具", items: [
            item("color_pick",   "取色器",  "eyedropper"),
            item("view_check",   "组件检查", "viewfinder"),
            item("view_align",   "对齐标尺", "arrow.left.and.right"),
            item("view_metrics", "布局边框", "rectangle"),
            item("ui_hierarchy", "UI结构",  "list.bullet.indent"),
        ])

        // MARK: Weex（4）

        let weex = DoSwiftToolGroup(title: "Weex", items: [
            item("weex_log",     "日志",    "list.dash"),
            item("weex_storage", "缓存",    "tray"),
            item("weex_info",    "信息",    "info"),
            item("weex_devtool", "DevTool", "hammer"),
        ])

        // MARK: 平台工具（3）

        let platform = DoSwiftToolGroup(title: "平台工具", items: [
            item("mock",      "Mock数据", "wand.and.stars"),
            item("health",    "健康体检", "waveform.path.ecg"),
            item("file_sync", "文件同步", "arrow.2.circlepath"),
        ])

        let groups = [common, performance, visual, weex, platform]

        #if DEBUG
        validate(groups)
        #endif

        return groups
    }

    // MARK: - Private

    /// 构造一个工具项。`symbol` 同时写进 `userInfo`，这样图标解析失败时
    /// 校验器还能报出是哪个符号名丢了（`UIImage(systemName:)` 失败只返回 nil，
    /// 不会留痕）。
    private static func item(_ id: String, _ title: String, _ symbol: String) -> DoSwiftMenuItem {
        let tool = DoSwiftMenuItem(identifier: id, title: title, icon: UIImage(systemName: symbol))
        tool.userInfo["symbol"] = symbol
        return tool
    }

    #if DEBUG
    /// 启动时把目录状态打到控制台。这是第 2 步唯一的手动验收手段——
    /// 图标名拼错、id 重名都不会崩，只会静默变空白，所以必须主动报出来。
    private static func validate(_ groups: [DoSwiftToolGroup]) {
        let items = groups.flatMap { $0.items }
        print("[ToolRail] loaded \(items.count) tools in \(groups.count) groups")

        var seen = Set<String>()
        for group in groups {
            for tool in group.items {
                if !seen.insert(tool.identifier).inserted {
                    print("[ToolRail] duplicate id: \(tool.identifier)")
                }
                if tool.icon == nil {
                    let symbol = tool.userInfo["symbol"] as? String ?? "?"
                    print("[ToolRail] missing SF Symbol \"\(symbol)\" for \(tool.title) (id: \(tool.identifier))")
                }
            }
        }
    }
    #endif
}
