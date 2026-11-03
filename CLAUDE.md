# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概述

DoSwift 是基于 DoKit-iOS 重构而来的纯 Swift iOS 调试工具库，不依赖任何第三方库。
最低版本 iOS 13，公开 API 挂在 `public enum DO {}` 命名空间下。

## 目录结构

```
DoSwift/
├── Code/                          # 全部源码（唯一 target）
│   ├── DO.swift                   # public enum DO {} —— 全库命名空间
│   ├── AppInfo/                   # App / 设备 / 权限信息
│   ├── Common/                    # 通用组件
│   │   ├── FileBrowser/           # 文件浏览器（路径栏 + 列表 + 三个协议）
│   │   └── Trend/                 # 趋势图（折线 / 柱状 / 文本）
│   ├── Console/                   # 日志采集与控制台
│   ├── Hierarchy/                 # UI 结构检查器（JSON 数据驱动）
│   ├── MainMenu/                  # 浮窗入口、插件协议、分组菜单
│   ├── Network/                   # URLSession 抓包
│   ├── Perf/                      # CPU / 内存 / FPS
│   ├── Runtime/                   # Swizzler
│   ├── Sandbox/                   # 沙盒文件浏览器
│   └── UserDefaults/              # UserDefaults 浏览
├── Resources/                     # 随包资源
│   └── DoSwiftHierarchyDefine.json
├── Example/                       # CocoaPods dev pod 示例工程（XcodeGen）
├── Tests/                         # SPM 测试
├── Scripts/ci.sh
├── DoSwift.podspec
└── Package.swift
```

`Code/` 与 `Resources/` 是**平级**的顶层目录，打包方式各异：

- **CocoaPods**：`source_files = 'Code/**/*.{swift,m,h}'`，资源走
  `resource_bundles => { 'DoSwiftResources' => ['Resources/**/*.{json}'] }`
- **SPM**：SwiftPM 只认包根目录之下的资源，所以 target 声明为 `path: "."`，再用
  `sources: ["Code"]` / `resources: [.process("Resources")]` 收窄，其余目录列进 `exclude`

## 开发命令

```bash
cd Example
xcodegen generate     # 仅改动 project.yml 后需要
pod install
open DoSwiftExample.xcworkspace
```

## 模块骨架

- **命名空间**：`public enum DO {}`，所有类型写成 `extension DO { ... }`；对外可见的加 `public`。
- **插件**：`DO.Plugin`（`identifier` / `title` / `icon` / `actionHandler`）+ 基类
  `DO.DefaultPlugin`（`shared` / `prepare()` / `show` / `hide` 的窗口骨架）。
  `DO.Core.shared.setup(appWindow:plugins:)` 注册并显示浮窗；自定义插件排在最前的 `Custom` 组。
- **窗口**：每个工具**各建自己的** `DO.OverlayWindow`（level 一般 `.alert - 1`），不共享宿主；
  层级工具登记 `addNoResponseView` 让触摸透到业务 App，信息展示类工具不登记。
- **列表页**：继承 `DO.SectionTableViewController`，用 `Section` / `Row(cellClass:onTrigger:configure:)`
  描述；cell 事件统一走 `SectionCellDelegate.trigger`，不特化 `didSelectRowAt`。
- **外观**：语义色（`.label` / `.secondaryLabel` / `systemBackground`）+ `.preferredFont`；
  cell 一律自绘——iOS 13 上 `textLabel` / `detailTextLabel` 已弃用，用系统 cell 等于踩弃用公告。

## Hierarchy：JSON 数据驱动

原版 DoKit 把「每个控件暴露哪些属性 + 枚举描述」写成几千行硬编码
（`NSObject+DoraemonHierarchy.m` 2527 行、`DoraemonEnumDescription.m` 880 行），本工程改为数据驱动：

- **`Resources/DoSwiftHierarchyDefine.json`** —— 唯一数据源
  - `Pinned`：置顶分组，`[{ group, properties }]`
  - `types`：`{ 类名: { properties: [KVC keyPath], overrides: { key: { enumType, userEditable } } } }`
  - `enums`：`{ 枚举名: { rawValue: 名称 } }`
- **`HierarchyPropertyEngine`**：按类继承链（`NSObject` → 子类）匹配条目，KVC 读值，生成
  `HierarchyCategoryModel` / `HierarchyCellModel`；写回需同时满足 `userEditable`、可解析的
  `ValueKind`、真实 setter，缺一即只读。编辑 UI 在 `UserInterface/Editor/`。
- **资源查找**：`Bundle.main` → `Bundle(for: engine)` → 各自的 `DoSwiftResources.bundle`。

数据驱动的取舍（已知、可接受）：
- 丢编译期类型检查——枚举 rawValue 是裸 int，靠 JSON 里的名字自解释
- KVC 边界：纯 Swift（非 `@objc`）属性读不到，只显示到父类层

## 验证

无第三方依赖，整库一条命令做完整编译期验证（zsh 下别把文件列表存进变量再展开）：

```bash
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios13.0-simulator $(find Code -name '*.swift')
```

SPM 侧：`swift build --triple arm64-apple-ios13.0-simulator --sdk "$SDK"`（产物在
`.build/arm64-apple-ios-simulator/debug/`，资源包名 `DoSwift_DoSwift.bundle`）。

## 原 DoKit-iOS 源码路径

```
/Users/admin/Documents/github/DoKit-iOS/iOS/DoraemonKit/Src/Core/Plugin/UI/Hierarchy/
```
