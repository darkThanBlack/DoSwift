# DoSwift 开发指南

## 项目结构

```
DoSwift/
├── Code/                          # 全部源码（唯一 target）
│   ├── DO.swift                   # public enum DO {} —— 全库命名空间
│   ├── AppInfo/                   # App / 设备 / 权限信息
│   ├── Common/                    # 通用组件
│   │   ├── FileBrowser/           # 文件浏览器：PathBarView + FileListView + 三个协议
│   │   └── Trend/                 # 趋势图：折线 / 柱状 / 文本，三种消费者同一取数接口
│   ├── Console/                   # 日志采集（stdout / stderr / os_log）与控制台
│   ├── Hierarchy/                 # UI 结构检查器
│   ├── MainMenu/                  # 浮窗入口、插件协议、分组菜单
│   ├── Network/                   # URLSession 抓包
│   ├── Perf/                      # CPU / 内存 / FPS 采样与报表
│   ├── Runtime/                   # Swizzler
│   ├── Sandbox/                   # 沙盒文件浏览器
│   └── UserDefaults/              # UserDefaults 浏览与删除
├── Resources/                     # 随包资源（与 Code/ 平级）
│   └── DoSwiftHierarchyDefine.json
├── Example/                       # CocoaPods dev pod 示例工程（XcodeGen 管理）
├── Tests/                         # SPM 测试目标
├── Scripts/ci.sh                  # 交互式开发脚本
├── DoSwift.podspec
└── Package.swift
```

打包口径：

| 集成方式 | 源码 | 资源 |
|---|---|---|
| CocoaPods | `Code/**/*.{swift,m,h}` | `resource_bundles => { 'DoSwiftResources' => ['Resources/**/*.{json}'] }` |
| SwiftPM | `target(path: ".")` + `sources: ["Code"]` | `resources: [.process("Resources")]` |

SwiftPM 只认包根目录之下的资源，而 `Resources/` 与 `Code/` 平级，所以 target 声明成包根，
再用 `sources` / `resources` 收窄、`exclude` 排掉 `Example` / `Tests` / `Scripts` 等目录。

## 开发环境

```bash
cd Example
xcodegen generate     # 只有改了 project.yml 才需要
pod install
open DoSwiftExample.xcworkspace
```

示例工程用 dev pod（`pod 'DoSwift', :path => '../'`）直接引用本仓库，改完源码重新构建即可，
不需要重装 pod。`Example/project.yml` 里 `platform: [iOS]` 会派生 target 名（`DoSwift_Example_iOS`），
所以显式写了 `platformSuffix: ""` 保住 `DoSwift_Example` 这个名字。

## 架构

### 1. 命名空间

全库只有 `public enum DO {}`，没有顶层符号。所有类型写成 `extension DO { ... }`，
对外可见的内容加 `public`。

### 2. 插件与入口

```swift
public protocol Plugin {
    var identifier: String { get }
    var title: String { get }
    var icon: UIImage? { get }
    var actionHandler: (() -> ())? { get }
}
```

- `DO.DefaultPlugin`：`shared` 单例 + `prepare()` + `show()` / `hide()` 的窗口骨架。
- `DO.Core.shared.setup(appWindow:plugins:)`：注册自定义插件、显示主菜单浮窗。
  推荐显式传入当前 App 的 window —— 自动探测 `keyWindow` 走的是兜底分支，不能保证 100% 准确。

### 3. 窗口

每个工具**各建自己的** `DO.OverlayWindow` 实例，不共享宿主。类共享的只有 `OverlayWindow`
本身，它比 `UIWindow` 多的唯一实质能力是 `addNoResponseView`（登记一个 view，命中时
`hitTest` 返回 nil，事件透到业务 App）。

- 层级工具（`HierarchyPlugin`）：登记 `noResponseView`，触摸要漏下去。
- 信息展示类工具（AppInfo / Console / Network / Sandbox / UserDefaults / Perf）：不登记，
  它们要改数据，事件漏下去是 bug。

level 一般用 `.alert - 1`，主菜单用 `.statusBar`。

### 4. 菜单与列表

`DO.Core` 内置三组：`Info`（AppInfo / Console / Network / UserDefaults / Sandbox）、
`Performance`（Perf）、`Visual`（Hierarchy），自定义插件插到最前的 `Custom` 组。

列表页统一继承 `DO.SectionTableViewController`，用 `Section` / `Row(cellClass:onTrigger:configure:)`
描述，cell 事件统一走 `SectionCellDelegate.trigger`（不特化 `didSelectRowAt`）。

### 5. 外观

一律取系统值：语义色（`.label` / `.secondaryLabel` / `systemBackground` / `.secondarySystemFill`）、
`.preferredFont(forTextStyle:)`、`.insetGrouped` 表格。cell 全部自绘 —— iOS 13 上
`textLabel` / `detailTextLabel` 已弃用，用系统 cell 反而踩弃用公告。

### 6. Hierarchy：JSON 数据驱动

把「每个控件暴露哪些属性 + 枚举描述」从几千行硬编码（`NSObject+DoraemonHierarchy.m` 2527 行、
`DoraemonEnumDescription.m` 880 行）搬进 `Resources/DoSwiftHierarchyDefine.json`：

- `Pinned`：置顶分组
- `types`：`{ 类名: { properties: [KVC keyPath], overrides: { key: { enumType, userEditable } } } }`
- `enums`：`{ 枚举名: { rawValue: 名称 } }`

`HierarchyPropertyEngine` 按类继承链匹配条目、KVC 读值；写回要求 `userEditable` + 可解析的
`ValueKind` + 真实 setter 三者齐备，否则该行保持只读。资源查找顺序：
`Bundle.main` → `Bundle(for: engine)` → 各自的 `DoSwiftResources.bundle`。

取舍（已知、可接受）：丢编译期类型检查（枚举 rawValue 是裸 int）；纯 Swift 非 `@objc`
属性读不到，只显示到父类层。

## 验证

无第三方依赖，整库一条命令做完整编译期验证（zsh 下别把文件列表存进变量再展开）：

```bash
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios13.0-simulator $(find Code -name '*.swift')
```

SPM：

```bash
swift build --triple arm64-apple-ios13.0-simulator --sdk "$SDK"
```

产物在 `.build/arm64-apple-ios-simulator/debug/`，资源包名 `DoSwift_DoSwift.bundle`。

## 已知限制

- **SPM 下 Hierarchy 的 JSON 找不到**：`HierarchyPropertyEngine` 只查 `DoSwiftResources.bundle`
  （CocoaPods 的 `resource_bundles` 名），SPM 生成的是 `DoSwift_DoSwift.bundle`。
  用 SPM 集成时这张属性表不会加载，面板里只剩内存里能反射到的部分。
- Console 的 stdout / stderr 只能看到「管道接上之后」的输出；Unified Log 需要 iOS 15。
- Network 只覆盖 `URLSession`：WKWebView / WebSocket / 裸 socket 抓不到，`httpBodyStream`
  上传抓不到。
