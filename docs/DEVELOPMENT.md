# DoSwift 开发指南

## 项目结构

```
DoSwift/
├── Code/                          # 全部源码（唯一 target）
│   ├── DO.swift                   # public enum DO {} —— 全库命名空间
│   ├── AppInfo/                   # App / 设备 / 权限信息
│   ├── Common/                    # 通用组件
│   │   ├── FileBrowser/           # 文件浏览器：PathBarView + FileListView + 三个协议
│   │   └── Trend/                 # 趋势图：折线 / 单行文本，同一取数接口，报表叠泳道
│   ├── Console/                   # 日志采集（stdout / stderr / os_log）与控制台
│   ├── Hierarchy/                 # UI 结构检查器
│   ├── MainMenu/                  # 浮窗入口、插件协议、分组菜单
│   ├── Network/                   # URLSession 抓包
│   ├── Perf/                      # CPU / 内存 / FPS 采样与报表
│   ├── Runtime/                   # Swizzler
│   ├── Sandbox/                   # 沙盒文件浏览器
│   └── UserDefaults/              # UserDefaults 浏览与删除
├── Resources/                     # 随包资源（与 Code/ 平级）
│   ├── DoSwiftHierarchyDefine.json
│   ├── en.lproj/Localizable.strings
│   └── zh-Hans.lproj/Localizable.strings
├── Example/                       # CocoaPods dev pod 示例工程（XcodeGen 管理，单 scene）
├── Tests/                         # SPM 测试目标
├── docs/                          # 开发指南
├── Scripts/ci.sh                  # 交互式开发脚本
├── DoSwiftKit.podspec
├── Package.swift
├── README.md                      # 英文（GitHub 默认）
└── README-zh-CN.md                # 简中
```

打包口径：

| 集成方式 | 源码 | 资源 |
|---|---|---|
| CocoaPods | `Code/**/*.{swift,m,h}` | `resource_bundles => { 'DoSwiftKitResources' => ['Resources/**/*.{json,strings}'] }` |
| SwiftPM | `target(path: ".")` + `sources: ["Code"]` | `resources: [.process("Resources")]` |

SwiftPM 只认包根目录之下的资源，而 `Resources/` 与 `Code/` 平级，所以 target 声明成包根，
再用 `sources` / `resources` 收窄、`exclude` 排掉 `Example` / `Tests` / `Scripts` 等目录。
白名单是 `sources` / `resources`，`exclude` 只负责消掉 unhandled-files 警告（列表过期只报警告，不报错）。
有本地化资源时必须声明 `defaultLocalization`，这里取 `"en"`，与源语言一致。

## 开发环境

```bash
cd Example
xcodegen generate     # 只有改了 project.yml 才需要
pod install
open DoSwiftExample.xcworkspace
```

顺序不能反：`xcodegen generate` 是整份重写 `.xcodeproj`，会把 `pod install` 写进去的
xcconfig 和 Pods 链接一起抹掉，表现是 `Unable to find module dependency: 'DoSwift'`。
示例工程是单 `UIWindowScene`，window 建在 `SceneDelegate` 里。

示例工程用 dev pod（`pod 'DoSwiftKit', :path => '../'`）直接引用本仓库，改完源码重新构建即可，
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

- `DO.DefaultPlugin`：`show()` / `hide()` / `makeWindow()` 的窗口骨架，子类各自提供 `shared`。
- `DO.Core.shared.setup(appWindow:appScene:plugins:)`：注册自定义插件、显示主菜单浮窗。
  推荐 window 和 scene 都显式传入 —— 自动探测走的是兜底分支，多 scene 下不能保证准确。
  `appScene` 决定浮窗挂到哪个 `UIWindowScene`；只传 window 时会用它的 `windowScene`。

### 3. 窗口

每个工具**各建自己的** `DO.OverlayWindow` 实例，不共享宿主。类共享的只有 `OverlayWindow`
本身，它比 `UIWindow` 多的唯一实质能力是 `addNoResponseView`（登记一个 view，命中时
`hitTest` 返回 nil，事件透到业务 App）。构造时优先挂到 `DO.Core.appScene`，没有才按
前台 scene 猜。

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

### 6. 注释

一律英文，一到两行。只写「为什么」——为什么这里要这样绕、为什么默认值是这个、踩过什么坑。
「做了什么」由代码本身表达，不重复。开发期日志与断言里的文案也是英文。

### 7. Hierarchy：JSON 数据驱动

把「每个控件暴露哪些属性 + 枚举描述」从几千行硬编码（`NSObject+DoraemonHierarchy.m` 2527 行、
`DoraemonEnumDescription.m` 880 行）搬进 `Resources/DoSwiftHierarchyDefine.json`：

- `Pinned`：置顶分组
- `types`：`{ 类名: { properties: [KVC keyPath], overrides: { key: { enumType, userEditable } } } }`
- `enums`：`{ 枚举名: { rawValue: 名称 } }`

`HierarchyPropertyEngine` 按类继承链匹配条目、KVC 读值；写回要求 `userEditable` + 可解析的
`ValueKind` + 真实 setter 三者齐备，否则该行保持只读。资源查找顺序：
`Bundle.main` → `DO.resourceBundle`（SPM 是 `Bundle.module`，CocoaPods 是 `DoSwiftKitResources.bundle`）。

取舍（已知、可接受）：丢编译期类型检查（枚举 rawValue 是裸 int）；纯 Swift 非 `@objc`
属性读不到，只显示到父类层。

## 国际化

界面文案全部收在 `DO.Text`（`Code/Common/DoSwiftText.swift`），调用点不出现裸字符串。
每条是一个 key + 英文兜底：

```swift
static let copyPath = DO.Text.string("sandbox.action.copy_path", "Copy Path")
static func recordCount(_ count: Int) -> String {
    return DO.Text.format("sandbox.database.record_count", "%d records", count)
}
```

- 表在 `Resources/{en,zh-Hans}.lproj/Localizable.strings`，源语言 `en`
- `DO.resourceBundle` 负责定位：SPM 是 `Bundle.module`（`DoSwiftKit_DoSwiftKit.bundle`），
  CocoaPods 是 `DoSwiftKitResources.bundle`；**两边都能命中**，缺失时退回英文 `value`
- 术语不翻译：UserDefaults / Sandbox / Bundle ID / URL / Method / Status / Duration /
  CPU / FPS / MB / os_log / fd1 等，中英两版都保持原词
- 复数没有用 `.stringsdict`：涉及数量的文案改成了与数量无关的写法
  （`Clear all captured lines (%d)?`），要精确单复数时再补 `.stringsdict`
- 新语言：加 `Resources/xx.lproj/Localizable.strings` 即可，代码不用动

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

产物在 `.build/arm64-apple-ios-simulator/debug/`，资源包名 `DoSwiftKit_DoSwiftKit.bundle`。

## 已知限制

- Console 的 stdout / stderr 只能看到「管道接上之后」的输出；Unified Log 需要 iOS 15。
- Network 只覆盖 `URLSession`：WKWebView / WebSocket / 裸 socket 抓不到，`httpBodyStream`
  上传抓不到。
