# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概述

DoSwift 是基于 DoKit-iOS 重构而来的纯 Swift iOS 调试工具库。

**重构完成状态**：
- ✅ **已完成重构**：基于 XiaoMai 项目中 PhotoDetectDrift.swift 和 Drift 模块的成熟架构完全重写
- ✅ **架构清理完成**：移除所有旧版本文件，基于 Drift 架构的新实现已稳定运行
- ✅ **构建验证通过**：CocoaPods dev pods 模式和 Example 项目构建成功

## 开发命令

### CocoaPods 开发模式 (主要方式)
```bash
cd DoSwift/Example
pod install                    # 安装开发依赖
open DoSwiftExample.xcworkspace # 打开开发工作区
```

### 构建和测试
- 构建: `xcodebuild -workspace DoSwiftExample.xcworkspace -scheme DoSwift_Example -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' build`
- 清理重装: `rm -rf Pods Podfile.lock && pod install`

### Swift Package Manager (辅助)
- 构建: `swift build` (注意：在 macOS 上会失败，因为使用了 UIKit)
- 测试: iOS 平台专用，需要使用 Xcode

## 当前架构状态

### 文件结构 (已完成)
```
DoSwift/Sources/DoSwift/
├── DoSwift.swift                    # 基础协议和命名空间
├── DoSwiftCore.swift                # 核心管理器(新Drift架构)
├── Window/
│   ├── DoSwiftWindow.swift          # 事件穿透窗口(Weaker包装器)
│   └── DoSwiftMenuItem.swift        # 菜单项模型
└── UI/
    ├── DoSwiftMainViewController.swift    # 主控制器
    ├── DoSwiftDriftView.swift            # 悬浮按钮(纯frame布局)
    └── DoSwiftMenuViewController.swift    # 菜单控制器
```

### 核心技术实现

#### 1. DoSwiftCore (单例管理器)
```swift
public class DoSwiftCore {
    public static let shared = DoSwiftCore()
    weak var appWindow: UIWindow?           // 主应用窗口弱引用
    public var window: DoSwiftWindow?       // DoSwift 窗口
    weak var mainController: DoSwiftMainViewController?

    public func setup(_ window: UIWindow?)  # 设置主窗口引用
    public func initialize(with menuItems: [DoSwiftMenuItem] = []) # 初始化菜单
    public func start()  # 显示悬浮窗
    public func stop()   # 隐藏悬浮窗
}
```

#### 2. DoSwiftWindow (事件穿透)
- 使用 `Weaker<UIView>` 弱引用包装器精确控制事件穿透
- 重写 `hitTest(_:with:)` 实现智能事件分发
- 基于 DriftWindow.swift 的成熟模式

#### 3. DoSwiftDriftView (悬浮按钮)
- **完全基于 frame 布局**，无 AutoLayout 依赖
- 使用 `touchesBegan/Moved/Ended` 实现流畅拖拽
- 智能边缘吸附算法 (`absorbHorizontal`)
- UserDefaults 位置持久化
- 3秒延时自动淡化效果
- **最新改进**：contentView 使用纯色块显示 (蓝色56x56 + 白色24x24图标)

#### 4. 菜单系统
- DoSwiftMenuItem 支持多级嵌套菜单
- DoSwiftMenuViewController 模态展示
- 支持动态添加/移除菜单项

### CocoaPods 配置

#### DoSwift.podspec (单一库结构)
```ruby
Pod::Spec.new do |s|
  s.name             = 'DoSwift'
  s.version          = '0.1.0'
  s.ios.deployment_target = '12.0'
  s.swift_versions = '5.0'

  # 单一库，不分子仓库
  s.source_files = 'Sources/DoSwift/**/*'

  s.frameworks = 'UIKit', 'Foundation'
  s.requires_arc = true
end
```

#### 开发模式集成
```ruby
# Example/Podfile
pod 'DoSwift', :path => '../'
```

## 重要技术决策记录

### 1. 架构选择 - Drift 模式
**决策时间**: 2025-09-26
**决策**: 完全基于 PhotoDetectDrift.swift 和 Drift 模块重构
**原因**:
- 原始 AutoLayout 方案存在冲突
- Drift 架构已在生产环境验证
- 提供成熟的事件穿透、拖拽、吸附算法

### 2. 布局方式 - 纯 Frame
**决策**: 移除所有 AutoLayout，使用纯 frame 计算
**实现**: DoSwiftDriftView.layoutSubviews 中手动设置 frame
**优势**: 避免约束冲突，性能更好

### 3. CocoaPods 结构 - 单一库
**决策**: 不使用子仓库分割，统一为 DoSwift 单库
**配置**: `s.source_files = 'Sources/DoSwift/**/*'`
**优势**: 简化依赖管理，适合中小型调试工具

### 4. 事件处理 - Weaker 包装器
**技术**: 使用 `Weaker<UIView>` 管理弱引用避免内存泄漏
**来源**: 参考 Drift 模块的成熟实现

## 使用方式

### 基本集成
```swift
// AppDelegate.swift
import DoSwift

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 设置主应用窗口引用
    DoSwiftCore.shared.setup(window)

    // 创建自定义菜单项
    let customMenuItems = createCustomMenuItems()

    // 初始化 DoSwift
    DoSwiftCore.shared.initialize(with: customMenuItems)

    // 仅在 Debug 模式下显示
    #if DEBUG
    DoSwiftCore.shared.start()
    #endif

    return true
}
```

### 自定义菜单
```swift
let menuItem = DoSwiftMenuItem(
    identifier: "custom_tool",
    title: "自定义工具",
    icon: UIImage(systemName: "wrench")
) { menuItem in
    // 功能实现
}

DoSwiftCore.shared.addMenuItem(menuItem)
```

## 当前状态总结

✅ **完成项**:
- 基于 Drift 架构的完整重构
- CocoaPods dev pods 开发环境
- 事件穿透和悬浮窗管理
- 拖拽、吸附、淡化等交互效果
- 多级菜单系统
- 单一库 podspec 配置
- DoSwiftDriftView 纯 frame 布局和色块显示

🎯 **当前可用功能**:
- 悬浮按钮显示和拖拽
- 边缘吸附动画
- 点击展开菜单界面
- 支持子菜单导航
- 位置记忆和淡化效果
- 动态添加菜单项

🚀 **开发状态**:
核心框架已完成，可正常构建和运行。Example 项目展示了完整的功能演示。

**最后更新**: 2025-09-26 17:55 (DoSwiftDriftView frame 布局改进完成)