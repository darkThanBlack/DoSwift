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

**最后更新**: 2025-09-29 交互式 UI Hierarchy + CI 脚本完成

## 开发工具脚本 (2025-09-29)

### CI 脚本工具

基于 XiaoMai s 工程的 `Scripts/ci.sh` 设计，简化版本只保留核心功能。

**使用方法**:
```bash
cd Scripts
./ci.sh
```

**功能列表**:
- `a1`: 打印环境变量 - 显示 Xcode 路径、工程路径等关键信息
- `b1`: 重新加载工程 - 执行 `pod install` 并自动打开工作空间
- `0`: 退出脚本

**实现特点**:
- 与 s 工程保持一致的脚本结构和交互方式
- 自动检测项目路径和 Xcode 安装位置
- 支持交互式菜单选择
- 适配 DoSwift 项目的 CocoaPods 结构

## 交互式 UI 结构查看器 (2025-09-29)

### 重构实现

根据用户提供的效果图，重构为浮窗式的交互式属性检查器：

**新实现架构**:
1. **DoSwiftHierarchyInspectorView.swift**: 黑色半透明卡片式属性浮窗
2. **DoSwiftInteractiveHierarchyViewController.swift**: 交互式控件选择控制器

**核心功能**:
- ✅ **点击选择**: 透明覆盖层拦截点击，自动选择对应控件
- ✅ **实时属性显示**: Name/Frame/Background/Text Color/Font 信息
- ✅ **红色边框高亮**: 选中控件显示红色边框，3秒自动消失
- ✅ **Parent Views**: 弹出选择器显示父视图层级
- ✅ **Subviews**: 显示所有子视图供选择
- ✅ **More Info**: 跳转到详细属性编辑页面

**技术亮点**:
- 单窗口架构，覆盖在主应用窗口之上
- 递归查找最深层可点击视图
- 自动过滤 DoSwift 相关视图避免干扰
- 流畅的入场/退场动画效果
- 十六进制颜色显示和 Clear Color 检测

**集成状态**:
- 已替换原有的表格式查看器
- 通过菜单 "UI 调试" → "UI 结构查看器" 启动
- 支持与详细属性页面的无缝切换

## UI 结构查看器迁移记录 (2025-09-27)

### DoKit-iOS 原始架构分析

**原始实现特点**:
1. **交互式指示器模式**: 启动后显示可拖拽的圆形指示器，用户通过拖拽来选择屏幕上的控件
2. **实时属性浮窗**: 底部显示跟随指示器选择的控件属性信息，支持拖拽重新定位
3. **多窗口架构**: DoKit 使用 `DoraemonHierarchyWindow` 等多个独立调试窗口

**关键组件**:
- `DKHierarchyPickerView`: 可拖拽的圆形选择指示器
- `DKHierarchyInfoView`: 实时属性显示浮窗
- `DoraemonHierarchyWindow`: 专用调试窗口
- `DoraemonHierarchyViewController`: 统一管理所有调试组件

### DoSwift 重构架构决策

**重要架构变更 - 单窗口设计**:

**DoKit 方式**: 多个独立 UIWindow + 窗口层级管理
```objective-c
// DoKit 使用多个独立调试窗口
DoraemonHierarchyWindow *hierarchyWindow = [[DoraemonHierarchyWindow alloc] init];
hierarchyWindow.windowLevel = UIWindowLevelAlert - 1;
```

**DoSwift 方式**: 单一 DoSwiftWindow + 统一事件穿透
```swift
// DoSwift 复用单一窗口架构，避免多窗口复杂性
DoSwiftCore.shared.window  // 统一的调试窗口
DoSwiftCore.shared.pushViewController(hierarchyViewController) // 导航管理
```

**架构优势**:
1. **简化窗口管理**: 避免多窗口生命周期复杂性
2. **统一事件处理**: 基于导航控制器的成熟事件分发
3. **减少系统资源**: 单窗口减少内存和渲染开销
4. **一致用户体验**: 统一的导航模式，符合 iOS 设计规范

### 已完成的 UI Hierarchy 功能

**实现文件**:
```
Sources/DoSwift/UI/ViewHierarchy/
├── DoSwiftHierarchyModels.swift      # 数据模型 (DoSwiftViewNode, DoSwiftProperty)
├── DoSwiftHierarchyHelper.swift      # 窗口管理和层级遍历
├── DoSwiftPropertyInspector.swift    # 动态属性检查和修改 (KVC)
├── DoSwiftHierarchyViewController.swift  # 主界面控制器 (分段控制)
└── DoSwiftHierarchyCells.swift       # 自定义表格单元格
```

**核心功能**:
- ✅ 视图层级遍历 (支持 iOS 13+ Scene-based)
- ✅ 动态属性编辑 (Key-Value Coding 实现)
- ✅ 属性分类展示 (基础、布局、外观、交互等)
- ✅ 视图高亮显示 (红色边框覆盖层)
- ✅ 实时属性修改 (UISwitch, UIStepper, 颜色选择器)

**技术实现亮点**:
```swift
// 使用 KVC 替代 Objective-C Runtime 进行属性修改
public func updateProperty(_ property: DoSwiftProperty, newValue: Any?) {
    let convertedValue = try convertValue(newValue, for: property.type)
    targetView.setValue(convertedValue, forKeyPath: property.keyPath)
}

// 兼容 iOS 13+ Scene-based 窗口获取
if #available(iOS 13.0, *) {
    for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene {
            allWindows.append(contentsOf: windowScene.windows)
        }
    }
}
```

### 菜单系统集成

**集成方式**:
- 在 `DoSwiftCore.createDefaultMenuItems()` 中添加 "UI 调试" 分类
- "UI 结构查看器" 作为子菜单项，点击后推入层级查看界面
- 修复了菜单选择后立即返回的问题 (DoSwiftMainViewController.swift:112)

**修复的关键 bug**:
```swift
// 修复前: 所有非 close 动作都会立即返回主界面
if menuItem.identifier != "close" {
    navigationController?.popToRootViewController(animated: true)
}

// 修复后: 只有 close 动作才返回，其他动作保持导航状态
if menuItem.identifier == "close" {
    navigationController?.popToRootViewController(animated: true)
}
```

### 未来改进方向

**潜在的交互式模式**:
如果需要实现类似 DoKit 的交互式指示器模式，可以考虑：
1. 在当前 DoSwiftWindow 中添加拖拽指示器视图
2. 使用坐标转换处理跨窗口位置计算
3. 实现实时属性浮窗跟随选择更新
4. 保持单窗口架构的简洁性

**当前实现评估**:
- ✅ 功能完整: 覆盖 DoKit UI Hierarchy 的核心功能
- ✅ 架构清晰: 单窗口设计避免复杂性
- ✅ 技术成熟: 基于 KVC 的动态属性修改可靠稳定
- ✅ 用户体验: 符合 iOS 导航设计模式