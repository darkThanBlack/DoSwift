# DoSwiftKit 代码质量评估报告

- 评估对象：`DoSwiftKit` v1.0.0（`main`）
- 评估日期：2026-11-04
- 评估基线：当前工作区代码（含 2026-11-04 的整改），不是初评快照
- 评估目的：判断是否可以在业务工程中引入，以及引入时需要防范什么

---

## 一、结论

**建议采用，综合评分 8.3 / 10；仅限 DEBUG 构建，并按第六节的清单接入。**

这是一个成熟的「单人全量重写」作品：结构克制、注释质量高于多数开源调试库、SPM 与 CocoaPods 两条打包通路都验证通过、零第三方依赖。主干逻辑（Swizzler、抓包状态机、控制台采集、层级属性引擎）的实现质量明显高于同类工具。

当前主要缺口不在代码本身，而在**工程流程**：测试只覆盖 3 个模块、没有自动化 CI。另有一处私有 API 用法（系统色名）和两处资源边界（抓包内存上限、stdio 缓冲模式）值得在接入前知晓。Swift 6 语言模式的适配成本客观存在，但在 iOS 13 / Swift 5.9 基线下不是必答题，见第四节「未来事项」。

| 维度 | 评分 | 说明 |
|---|---|---|
| 架构与模块划分 | 9.0 | 单一命名空间、插件协议、每工具独立浮窗，职责边界清楚 |
| 可读性 | 9.0 | 注释只写「为什么」；113 个文件里仅 9 个超过 300 行；命名一致 |
| 正确性与健壮性 | 8.0 | 已无 `try!` / `as!` / 无界增长 / 私有 UIAction KVC；剩跨线程状态、私有色名 KVC、两处资源边界 |
| 测试 | 6.5 | 25 个用例质量不错，但 Hierarchy / Perf / Sandbox / AppInfo 零覆盖 |
| 文档与国际化 | 9.0 | 228 键双语完全对齐；文档签名与资源 glob 与实际一致 |
| 打包与发布 | 8.5 | SPM 与 CocoaPods 均编译通过；缺自动化 CI |
| **综合** | **8.3** | |

---

## 二、评估方法与可复现结果

### 2.1 规模

| 指标 | 数值 |
|---|---|
| Swift 文件 | 113 |
| Swift 代码行 | 14,421 |
| 功能模块 | AppInfo / Common / Console / Hierarchy / MainMenu / Network / Perf / Runtime / Sandbox / UserDefaults |
| 第三方依赖 | 0 |
| 部署目标 / 语言模式 | iOS 13.0 / Swift 5.9（`swift-tools-version: 5.9`，按 Swift 5 语言模式编译） |
| 测试文件 / 用例 | 6 / 25 |
| 本地化键 | 228（en 与 zh-Hans 完全一致） |
| `public` / `open` 声明 | 47，集中在 `DO.Core`、`Plugin` 协议、`DefaultPlugin` 与各工具单例 |

### 2.2 编译验证

```bash
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios13.0-simulator $(find Code -name '*.swift')
# -> exit 0，无任何诊断输出

swift build --triple arm64-apple-ios13.0-simulator --sdk "$SDK"
# -> Build complete!，无 warning
```

两点值得肯定：

- 在 iOS 26.2 SDK 下以 iOS 13 为部署目标编译，**零 warning**（同类库常在 `traitCollectionDidChange`、`UIScreen.main` 上翻车）；
- SPM 的 `path: "."` + `sources` / `resources` 收窄方案真实可用，资源包 `DoSwiftKit_DoSwiftKit.bundle` 能正常生成。

### 2.3 静态扫描

| 检查项 | 结果 |
|---|---|
| `try!` / `as!` | 0 |
| 强制解包 | 11 处，全部是 `NetworkCapture` 对已捕获 IMP 的 `original!`：hook 只有安装成功才会执行，且非 Void 方法没有合法降级返回值 |
| TODO / FIXME | 0 |
| 弃用 API（`textLabel` / `detailTextLabel`） | 0（cell 全部自绘，这是正确的取舍） |
| 本地化键缺失 / 冗余 | 0 / 0 |
| 对 UIKit 类型的扩展 | 0（唯一的类型扩展是 `Array where Element == DO.TrendPoint`，只作用于自家元素类型） |

### 2.4 测试执行

```bash
xcodebuild test -scheme DoSwiftKit \
  -destination 'platform=iOS Simulator,name=iPhone 16'
# ** TEST SUCCEEDED **
```

明细见第八节。

---

## 三、值得肯定的设计决策

1. **Swizzler 用 `class_replaceMethod` 而非 `method_exchangeImplementations`**（`Runtime/Swizzler.swift`）。交换实现会污染父类和兄弟类，这里避开了；按 `(类, selector)` 去重，重复安装不会叠加；`cast` 明确要求「不含 `_cmd`」的 block 签名，注释把坑写在了调用点旁边。
2. **每个工具各建 `DO.OverlayWindow`，用 `addNoResponseView` 精确控制触摸穿透**（`Common/OverlayWindow.swift`）。层级工具穿透、数据工具不穿透，这个区分做得很细。
3. **Hierarchy 从 3400 行 ObjC 硬编码改为 JSON 数据驱动**。`HierarchyPropertyEngine` 沿继承链匹配、KVC 读值；写回要求「`userEditable` + 可解析 kind + 真实 setter」三者齐备，缺一即只读。取舍（丢编译期检查、纯 Swift 属性读不到）在文档里写明了，是诚实的工程决策。
4. **网络抓包的状态机**：`NetworkTaskBox` 用「首次 finish 胜出」保证 completion handler 与 delegate 回调不重复记录；body 抓取时即截断，`truncated` 如实上报，而不是悄悄截掉。
5. **控制台采集的细节**：`dup2` 接管 fd1/fd2 时设置 `F_SETNOSIGPIPE`、读端非阻塞、按括号/超时合并续行、缓冲区上限 2000 行、通知按 200ms 节流。这些都是踩过坑才会写的代码。
6. **国际化体系**：所有文案走 `DO.Text`，每次调用都带英文 fallback，键在 `en` / `zh-Hans` 完全对齐，且没有未使用键——比大多数项目的文案管理干净。
7. **隐私清单**：`PrivacyInfo.xcprivacy` 三处 required-reason API（UserDefaults CA92.1、FileTimestamp C617.1、SystemBootTime 35F9.1）都写上了，声明不采集数据。
8. **配置解码的向后兼容**：`ConsoleSettings` 和 `HierarchyConfig` 都手写 `init(from:)`，新字段缺失时回退默认值，老版本已存的数据不会把配置清空；测试里也专门验证了这一点。
9. **边界收敛**：性能历史有固定上限（`DO.PerfHistory`，约 1.8 万点 + 10% 余量），浮窗尺寸统一走 `DO.Core.screenBounds`，颜色/格式化逻辑集中在 `HierarchyFormatterTool`，库不给 UIKit 类型加任何成员。

---

## 四、剩余问题与已知取舍

### 剩余问题

#### P1-1 `NetworkCapture.isEnabled` 跨线程读写无同步

> 维护者评估：可接受，不阻塞接入（最多多记一条，时效性无要求）。列出是因为它在 TSan 下会报，接入方应知情。

- 位置：`Code/Network/NetworkCapture.swift:38`，读取处 `90 / 106 / 120 / 133`
- 现象：`private(set) var isEnabled = false` 是普通 `Bool`；写入发生在主线程（UI 开关 / `start()`），读取发生在被 hook 的 `URLSession` 方法里——任意线程。
- 影响：数据竞争。表现为「刚关掉又记录了一条」；Thread Sanitizer 下会明确报告，是回归噪音源。
- 建议：用该类已有的 `lock` 或原子封装保护；顺便把 `sessionClasses` 的读取也纳入锁内。

#### P2-1 抓包内存上限固定且偏大

- 位置：`Code/Network/NetworkCapture.swift`（`capacity = 200`）+ `NetworkRecord.swift`（`maxBytes = 64 KB`）
- 现象：最多 200 条记录，每条请求体与响应体各 64 KB，理论峰值约 **25 MB**；容量与上限均无公开 API 可调。
- 影响：长会话或大响应场景下，调试库本身会成为内存问题的一部分。
- 建议：把 `capacity` / `maxBytes` 暴露为可配置（或按总字节数而非条数计费）；文档里写清默认值。

#### P2-2 停止控制台采集后未还原 stdio 缓冲模式

- 位置：`Code/Console/ConsoleCapture.swift:83-84` vs `:116-117`
- 现象：`start()` 把 `stdout/stderr` 设为行缓冲，`stop()` 统一改成 `_IOFBF`（全缓冲），但不恢复调用前的模式。
- 影响：宿主 App 在停止采集后的日志时序/落盘行为被悄悄改变；排查「为什么日志少了」时很难定位。
- 建议：`start()` 前记录原状态并在 `stop()` 还原，或在文档里明确写出这一副作用。

#### P2-3 读取系统色名依赖私有 KVC

- 位置：`Code/Hierarchy/HierarchyFormatterTool.swift` 的 `systemColorName(of:)`
- 现象：`color.value(forKey: "systemColorName")` 用来把 `.systemBlue` 和手搓的蓝色区分开。它不是公开属性，也不是 ObjC 方法（`UIColor.responds(to:)` 为 false），KVC 是靠私有 ivar 找到值的。
- 实测（iOS 26 模拟器）：`.systemBlue` → `systemBlueColor`，`.label` → `labelColor`；`.clear`、`.red` 与自绘色返回 `nil`，不抛异常。`description(of:)` 已先对 `.clear` 做特判。
- 影响：只读、当前版本稳定。唯一的实质风险是苹果移除该 ivar 后 KVC 会抛 `NSUnknownKeyException`（崩宿主），而不是显示退化。
- 建议：可接受；若要彻底干净，放弃系统色名、只显示 RGBA。

#### P3-1 测试覆盖不均衡

- 已覆盖：Swizzler 语义（5 个用例，含「hook 子类不污染父类」「重复安装幂等」这类关键性质）、网络抓包（completion / delegate / upload / 上限 / 容量淘汰）、控制台存储与设置。
- 未覆盖：Hierarchy（体量最大的模块，3,697 行）、Perf、Sandbox、UserDefaults、AppInfo、MainMenu。
- 建议：优先给 `HierarchyPropertyEngine` 补纯逻辑测试（class chain 匹配、`is` 前缀写回、枚举解析、只读判定），性价比最高。

#### P3-2 未做自动化 CI

- 仓库没有 `.github/workflows`，`Scripts/ci.sh` 是交互式脚本（只做 `pod install` + 打开工程）。
- 建议：至少加一条 PR 检查，跑第二节的两条编译命令；再把 `xcodebuild test` 挂上。

#### P3-4 控制台刷新是全量 `reloadData`

- 位置：`ConsoleViewController.swift` 的 `reload()`（由 200ms 通知驱动）。
- 现象：每次通知都 `visibleLines()`（O(n) 拷贝 + 过滤 + 合并）再 `tableView.reloadData()`，n 上限 2000。
- 影响：打日志密集时滚动位置与点击可能被打断（网络列表已经用 signature 做了同类优化，控制台没做）。
- 建议：比对行 id 前缀，只 `insertRows` / `reloadRows` 变化部分。

### 未来事项：Swift 6 语言模式（当前基线不要求）

当前基线是 iOS 13 + Swift 5.9：`Package.swift` 为 `swift-tools-version: 5.9`，podspec 为 `swift_versions = '5.9'`，模块按 Swift 5 语言模式编译。Swift 6 语言模式是 opt-in（tools-version 6.0 / `swiftLanguageMode(.v6)` / `SWIFT_VERSION = 6.0`），**不升级就没有迁移义务**；反过来，Swift 6 的 App 也可以正常引用本库——语言模式按模块生效。

两点澄清：

- **iOS 13 不是障碍**。async/await、actor、`@MainActor` 自 Swift 5.5 起可回部署到 iOS 13（部署目标低于 iOS 15 时自动链接并发运行库）。阻碍迁移的是语言模式，不是部署目标。
- **当前代码是并发"未标注"，不是"不可迁移"**。库内纯 GCD、无 `async/await`，所以现有行为没有并发正确性问题；但类型没有 `Sendable` / `@MainActor` 标注。

如果将来升级，实测成本：在 Swift 5 模式下打开 `-strict-concurrency=complete`，得到 **265 条**主诊断、0 error。分布如下：

| 类别 | 条数 |
|---|---|
| UIKit `@MainActor` 与库内非隔离类的冲突（属性读取 / 方法调用 / 初始化 / 默认值） | 187 |
| 协议一致性跨入主线程隔离 | 23 |
| 全局可变状态（`static let shared` 等） | 15 |
| 非 `Sendable` 捕获 | 14 |
| 其它 | 26 |

按目录：Hierarchy 98、Perf 50、AppInfo 34、MainMenu 23、Sandbox 15、Console 15、Network 11、Common 10、UserDefaults 8、Runtime 1。

对应的动作主要是集中标注，而不是重写：给 `DO.DefaultPlugin` / `DO.Core` / 各插件补 `@MainActor`，给 `Swizzler.originals` 加 `nonisolated(unsafe)` 与锁说明，给 `ConsoleStore` / `Perf*Source` 的回调标明隔离域。工作量以天计。

建议：保持 Swift 5 语言模式；新增代码不扩大可变全局状态即可。真要迁移时，先开 `-strict-concurrency=targeted` 观察增量，再逐模块推进。

### 已知取舍（评估过，可接受）

- **抓包 hook 永不卸载**：`stop()` 只关闸门，不还原 `URLSession` 方法，避免破坏叠在上面的其他框架。代价是与其它 hook 过 `URLSession` 的 SDK 存在耦合风险，接入时需联调。
- **控制台接管 fd1/fd2**：采集开始后 stdout/stderr 指向管道，`print` 可见但 fd 写入者受影响。属于工具语义本身，已通过显式 `start()` 控制。
- **Unified Log 需要 iOS 15**：低版本上该入口不可用，代码已做可用性判断。
- **`UIScreen.main.scale` 用于 1px 描边**：与场景无关，保持现状；浮窗 bounds 已统一收敛到 `DO.Core.screenBounds`（实现仍是 `UIScreen.main.bounds`，多 scene 适配留作后续单点修改）。
- **JSON 数据驱动的代价**：丢编译期类型检查（枚举 rawValue 是裸 int）；纯 Swift 非 `@objc` 属性读不到，只显示到父类层。

---

## 五、模块成熟度

| 模块 | 成熟度 | 说明 |
|---|---|---|
| Hierarchy（视图检查/取色/量距/属性编辑） | 高 | 项目核心，功能最完整；3,697 行；无 TODO 残留 |
| Network | 高 | hook 覆盖 `dataTask` / `uploadTask` 常用工厂；有测试；边界（WKWebView / WebSocket / `httpBodyStream`）已文档化 |
| Console | 高 | fd 接管 + os_log 查询；有测试；注意 P2-2 |
| Perf | 高 | 采样扎实，历史有固定上限；无自动化测试 |
| AppInfo | 高 | 权限枚举覆盖完整，含 iOS 13/14/15 可用性分支 |
| Sandbox / UserDefaults | 中高 | 功能完整，无测试 |
| MainMenu / 主题 | 高 | 自绘 cell、语义色、深浅色适配 |

---

## 六、接入建议（可直接照做）

1. **只在 DEBUG 里编译和调用。** 库内的 `#if DEBUG` 只用于断言和「Debug/Release」展示，初始化与采集入口没有保护；`start()` 一旦被调用就会全局 swizzle、接管 fd：

   ```swift
   #if DEBUG
   DO.Core.shared.setup(appScene: windowScene, appWindow: window)
   // 需要立即采集时再打开，注意这会接管 fd1/fd2
   DO.NetworkPlugin.shared.start()
   DO.ConsolePlugin.shared.start()
   #endif
   ```

2. **显式传 `appScene` 和 `appWindow`。** 自动探测（`connectedScenes.first` / `keyWindow`）在多 scene 下不可靠，库作者在注释里也承认了。
3. **评估与其他网络组件的冲突。** 本库对 `URLSession` 的 hook 永不卸载，且会给 `delegate: nil` 的 session 注入一个 `DONetworkSessionDelegate`。如果工程里已有 APM / 抓包 SDK 也在 hook `URLSession`，务必做一次联调回归。
4. **接受这些全局副作用**：`ConsolePlugin.start()` 会把 stdout/stderr 重定向到管道；`NetworkPlugin.start()` 会给每条请求附加关联对象。
5. **内存预算**：抓包最多约 25 MB、控制台最多约 8 MB 文本（2000 行 × 4000 字符）、性能历史约 1.8 万点。低端机长时间开面板要留意。
6. **发布合规**：`PrivacyInfo.xcprivacy` 已随资源包分发，reason code 齐全；提审前确认 Xcode 的隐私报告里能看到这三类 API。不要把 `start()` 留在 Release。
7. **iOS 13 用户**：Console 的 Unified Log 查询需要 iOS 15（代码已做可用性判断），其余功能在 13 上可用。
8. **如果只想要一部分**：网络抓包、控制台、层级工具彼此独立，`DO.Core.setup(plugins:)` 之外也可以只调用某个 `Plugin.shared`；但主菜单浮窗依赖 `Core.setup`。
9. **许可证**：`LICENSE` 是 WTFPL v2，条款极宽松，但个别公司对 WTFPL 有内部政策，落地前走一遍法务确认。

---

## 七、如果要继续维护，建议的优先级

1. 给 `isEnabled` 加锁（30 分钟）
2. 把抓包 `capacity` / `maxBytes` 改成可配置，并在文档写清默认值（半天）
3. 还原 stdio 缓冲模式，或在文档中明确副作用（1 小时）
4. 补 `HierarchyPropertyEngine` 单元测试（半天）
5. 加 GitHub Actions 编译 + 测试（半天）
6. 控制台改为增量刷新（半天）

---

## 八、测试结果

```bash
xcodebuild test -scheme DoSwiftKit \
  -destination 'platform=iOS Simulator,name=iPhone 16'
# ** TEST SUCCEEDED **
```

| Suite | 用例 | 结果 |
|---|---|---|
| SwizzlerTests | 5 | 通过 |
| NetworkCaptureRecordTests | 6 | 通过 |
| NetworkCaptureTests | 4 | 通过 |
| ConsoleListRenderingTests | 2 | 通过（真实 UIWindow + 表格渲染） |
| ConsoleMergeTests | 3 | 通过 |
| ConsoleSettingsTests | 3 | 通过 |
| ConsoleStoreCountTests | 1 | 通过 |
| DoSwiftKitTests | 1 | 通过（占位） |
| **合计** | **25** | **0 失败，约 1 s** |

用例不是凑数的：Swizzler 测了「hook 子类不影响父类」「二次安装幂等」；网络测了 completion handler、session delegate、upload body、截断、容量淘汰；控制台测了合并开关对存量数据的重排。缺失项已在 P3-1 说明。
