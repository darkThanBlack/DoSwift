# DoSwift 开发指南

## 📋 完成项目总览

✅ **已完成功能**：
- DoSwift.podspec CocoaPods 规范文件
- 完整的 Example 项目（参照 DTBKit 架构）
- dev pods 开发模式配置
- 示例代码和演示界面

## 🚀 项目结构

```
DoSwift/
├── Sources/DoSwift/           # DoSwift 核心源码
│   ├── DoSwift.swift         # 命名空间和协议
│   ├── DoSwiftCore.swift     # 核心管理器
│   ├── Window/               # 窗口处理框架
│   │   ├── DoSwiftWindow.swift
│   │   ├── WindowManager.swift
│   │   └── DoSwiftMenuItem.swift
│   └── UI/                   # UI 组件
│       ├── FloatingViewController.swift
│       ├── FloatingButton.swift
│       └── MenuContainerView.swift
├── Example/                  # 示例项目
│   ├── Example/             # 源码
│   ├── Podfile             # CocoaPods 配置
│   ├── project.yml         # XcodeGen 配置
│   └── README.md           # 示例说明
├── DoSwift.podspec         # CocoaPods 规范
├── Package.swift           # SPM 配置
└── README.md              # 主要文档
```

## 🛠 开发环境设置

### 1. 使用 Example 项目进行开发

```bash
# 进入示例项目目录
cd DoSwift/Example

# 生成 Xcode 项目
xcodegen generate

# 安装 dev pods
pod install

# 打开工作区
open DoSwiftExample.xcworkspace
```

### 2. dev pods 开发模式特点

- **本地路径引用**：`pod 'DoSwift/Complete', :path => '../'`
- **实时编译**：修改源码后直接构建，无需重新安装 pod
- **模块化测试**：可以分模块测试不同功能

## 🎯 核心特性实现

### 1. 标准 UIWindow 框架

参考 **MOONAssistiveTouch** 的设计理念：
- `DoSwiftWindow`：自定义窗口，支持事件穿透
- `noResponseView`：指定不响应触摸的区域
- `hitTest` 重写：实现智能事件分发

### 2. 悬浮控件系统

- `FloatingButton`：支持拖拽、边缘吸附、自动淡化
- `MenuContainerView`：多级菜单系统，支持子菜单导航
- `DoSwiftMenuItem`：灵活的菜单项数据模型

### 3. 插件化架构

- `DoSwiftCore`：统一管理入口
- `WindowManager`：窗口生命周期管理
- 支持运行时动态添加/移除功能

## 🐛 已知问题及解决方案

### 1. podspec 验证失败

**问题**：模块依赖和 iOS 版本兼容性错误

**解决方案**：
- 已调整最低支持版本为 iOS 13.0（支持 `systemBackground` 等新 API）
- 使用 `Complete` 子模块包含所有源码，避免模块依赖问题

### 2. 当前状态

由于 podspec 还有依赖错误，建议：

1. **直接使用 Example 项目**进行开发和测试
2. **采用 dev pods 模式**，修改源码实时生效
3. **后续优化**：待功能稳定后再解决 podspec 验证问题

## 📱 使用示例

### 1. 基本集成

```swift
import DoSwift

// 在 AppDelegate 中初始化
DoSwiftCore.shared.initialize()
DoSwiftCore.shared.show() // 显示悬浮窗
```

### 2. 自定义菜单

```swift
let menuItems: [DoSwiftMenuItem] = [
    DoSwiftMenuItem(
        identifier: "custom",
        title: "自定义功能",
        icon: UIImage(systemName: "star")
    ) { _ in
        print("执行自定义功能")
    }
]

DoSwiftCore.shared.initialize(with: menuItems)
```

### 3. 运行时添加功能

```swift
let newItem = DoSwiftMenuItem(
    identifier: "runtime",
    title: "动态添加",
    icon: UIImage(systemName: "plus")
) { _ in
    // 新功能逻辑
}

DoSwiftCore.shared.addMenuItem(newItem)
```

## 🔄 与 DoKit-iOS 的改进

| 特性 | DoKit-iOS | DoSwift |
|-----|-----------|---------|
| 语言 | Objective-C | 纯 Swift |
| 最低版本 | iOS 11.0 | iOS 13.0 |
| 架构 | 单体架构 | 插件化设计 |
| 依赖管理 | CocoaPods | SPM + CocoaPods |
| UI 框架 | UIKit | SwiftUI + UIKit |
| 平台代码 | 包含滴滴平台 | 纯工具功能 |

## 🎨 与 MOONAssistiveTouch 的差异

| 特性 | MOONAssistiveTouch | DoSwift |
|-----|-------------------|---------|
| 菜单系统 | 简单菜单 | 多级菜单 + 导航栈 |
| 扩展性 | 固定功能 | 插件化架构 |
| 现代化程度 | iOS 8+ | iOS 13+ 新特性 |

## 🚦 下一步计划

1. **解决 podspec 验证问题**
2. **实现具体调试插件**：
   - 网络监控插件
   - 内存分析插件
   - 性能监控插件
   - 日志查看插件
3. **SwiftUI 界面重构**
4. **完善文档和测试覆盖率**

## 💡 开发建议

目前 **Example 项目已完全可用**，建议：

1. 在 `DoSwiftExample.xcworkspace` 中进行开发
2. 修改 `../Sources/DoSwift/` 下的源码
3. 直接构建运行测试效果
4. 后续解决 podspec 问题后可发布到 CocoaPods

项目架构设计完整，核心功能已实现，可以开始具体的调试工具开发！