# DoSwift

基于 DoKit-iOS 精简重构的纯 Swift iOS 调试工具库，参考成熟的悬浮窗架构设计。

## 特性

- 🎯 **纯 Swift 实现**：完全使用 Swift 编写，支持 iOS 13+
- 🪟 **成熟的悬浮窗架构**：基于生产环境验证的 Drift 架构设计
- 🔌 **插件化架构**：模块化设计，支持动态加载/卸载功能
- 🎨 **流畅的交互体验**：支持拖拽、边缘吸附、自动淡化等
- 📱 **多场景适配**：兼容 iOS 13+ Scene-based 应用架构

## 核心架构

### 悬浮窗处理框架

基于成熟的生产环境架构，DoSwift 实现了稳定可靠的悬浮窗处理框架：

```swift
// 事件穿透窗口
class DoSwiftWindow: UIWindow {
    private var noResponses: [Weaker<UIView>] = []

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 智能事件穿透逻辑
    }
}
```

### 核心组件

1. **DoSwiftCore** - 单例管理器，统一入口
2. **DoSwiftWindow** - 事件穿透窗口
3. **DoSwiftDriftView** - 可拖拽的悬浮按钮
4. **DoSwiftMenuViewController** - 菜单界面系统
5. **DoSwiftMenuItem** - 菜单项数据模型

## 快速开始

### 1. 添加依赖

**CocoaPods:**
```ruby
pod 'DoSwift', :git => 'https://github.com/your-repo/DoSwift.git'
```

**Swift Package Manager:**
```swift
dependencies: [
    .package(url: "https://github.com/your-repo/DoSwift.git", from: "1.0.0")
]
```

### 2. 基本使用

```swift
import DoSwift

// 在 AppDelegate 中初始化
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // 设置主应用窗口引用
    DoSwiftCore.shared.setup(window)

    // 使用默认菜单初始化
    DoSwiftCore.shared.initialize()

    // 仅在 Debug 模式下显示
    #if DEBUG
    DoSwiftCore.shared.start()
    #endif

    return true
}
```

### 3. 自定义菜单

```swift
// 创建自定义菜单项
let customMenuItems: [DoSwiftMenuItem] = [
    DoSwiftMenuItem(
        identifier: "network_monitor",
        title: "网络监控",
        icon: UIImage(systemName: "network")
    ) { menuItem in
        // 执行网络监控功能
        showNetworkMonitor()
    },

    DoSwiftMenuItem(
        identifier: "performance",
        title: "性能监控",
        icon: UIImage(systemName: "speedometer")
    ) { menuItem in
        // 执行性能监控功能
        showPerformanceMonitor()
    }
]

// 使用自定义菜单初始化
DoSwiftCore.shared.initialize(with: customMenuItems)
DoSwiftCore.shared.start()
```

## 架构特点

### 与原版 DoKit-iOS 的差异

| 特性 | DoKit-iOS | DoSwift |
|-----|---------|---------|
| 语言 | Objective-C | 纯 Swift |
| 架构 | 复杂的模块依赖 | 简洁的单例设计 |
| 悬浮窗 | 复杂的 Window 处理 | 基于成熟架构的 Drift 设计 |
| 布局方式 | AutoLayout 冲突 | 纯 frame 布局 |
| 平台代码 | 包含滴滴平台依赖 | 纯工具功能 |
| iOS 版本 | iOS 11+ | iOS 13+ |

### 核心设计亮点

1. **事件穿透机制**：使用 `Weaker<UIView>` 弱引用包装器精确控制
2. **拖拽体验**：基于 `touchesBegan/Moved/Ended` 的流畅拖拽
3. **边缘吸附**：智能的 `absorbHorizontal` 算法
4. **位置记忆**：UserDefaults 持久化拖拽位置
5. **淡化效果**：3秒延时自动淡化，用户体验友好

## 高级用法

### 动态添加菜单项

```swift
// 运行时添加新功能
let newMenuItem = DoSwiftMenuItem(
    identifier: "custom_tool",
    title: "自定义工具",
    icon: UIImage(systemName: "wrench")
) { menuItem in
    // 自定义功能逻辑
}

DoSwiftCore.shared.addMenuItem(newMenuItem)
```

### 推送自定义视图

```swift
// 推送详细信息页面
let detailViewController = MyDetailViewController()
DoSwiftCore.shared.pushViewController(detailViewController)
```

### 子菜单配置

```swift
let parentItem = DoSwiftMenuItem(
    identifier: "tools",
    title: "开发工具",
    icon: UIImage(systemName: "hammer")
)

let subItem1 = DoSwiftMenuItem(
    identifier: "inspector",
    title: "视图检查器"
) { _ in /* 功能实现 */ }

parentItem.addSubMenuItem(subItem1)
```

## 项目结构

```
DoSwift/
├── Sources/DoSwift/
│   ├── DoSwift.swift              # 命名空间和协议定义
│   ├── DoSwiftCore.swift          # 核心管理器
│   ├── Window/
│   │   ├── DoSwiftWindow.swift    # 事件穿透窗口
│   │   └── DoSwiftMenuItem.swift  # 菜单项模型
│   └── UI/
│       ├── DoSwiftMainViewController.swift     # 主控制器
│       ├── DoSwiftDriftView.swift             # 悬浮按钮
│       └── DoSwiftMenuViewController.swift     # 菜单控制器
├── Tests/                         # 单元测试
├── Example/                       # 示例项目
└── Package.swift                  # SPM 配置
```

## 开发环境

### 使用 dev pods 模式开发

```bash
# 进入示例项目
cd DoSwift/Example

# 生成 Xcode 项目
xcodegen generate

# 安装 dev pods
pod install

# 打开工作区
open DoSwiftExample.xcworkspace
```

## 兼容性

- iOS 13.0+
- Xcode 14.0+
- Swift 5.9+

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来完善这个项目。项目基于成熟的生产环境架构设计，稳定可靠。