# DoSwift Example

这个示例项目演示了如何使用 DoSwift 调试工具库。

## 项目结构

```
DoSwift/Example/
├── Example/                    # 示例源码
│   ├── AppDelegate.swift       # 应用程序入口和 DoSwift 初始化
│   ├── ViewController.swift    # 主界面控制器
│   ├── Info.plist             # 应用信息
│   └── LaunchScreen.storyboard # 启动页
├── Podfile                    # CocoaPods 配置
├── project.yml               # XcodeGen 配置
└── README.md                 # 说明文档
```

## 开发环境配置

### 1. 使用 XcodeGen 生成项目

```bash
cd DoSwift/Example
xcodegen generate
```

### 2. 安装 CocoaPods 依赖

```bash
pod install
```

### 3. 打开工作区

```bash
open DoSwiftExample.xcworkspace
```

## dev pods 开发模式

本项目使用 dev pods 模式进行开发，这意味着：

1. **本地路径引用**：Podfile 中使用 `:path => '../'` 直接引用上级目录的 DoSwift 源码
2. **实时编译**：修改 DoSwift 源码后，重新构建即可看到效果，无需重新安装 pod
3. **模块化测试**：可以分别测试 DoSwift 的不同模块（Core、Window、UI）

### Podfile 配置

```ruby
# Development pods using path for local development
pod 'DoSwift/Core', :path => '../'
pod 'DoSwift/Window', :path => '../'
pod 'DoSwift/UI', :path => '../'
```

## 功能演示

### 1. 基础功能

- **悬浮按钮**：可拖拽的圆形按钮，支持边缘吸附
- **多级菜单**：点击按钮显示菜单，支持子菜单导航
- **事件穿透**：背景区域点击不影响主应用交互

### 2. 示例菜单项

- 应用信息：显示当前应用的基本信息
- 网络工具：网络监控和日志查看（含子菜单）
- 性能监控：CPU、内存使用情况
- UI 调试：界面调试工具
- 内存分析：内存使用详情
- 设置：主题切换和关于信息（含子菜单）

### 3. 动态功能

- **运行时添加菜单**：点击"添加菜单项"按钮动态添加新功能
- **显示/隐藏控制**：通过代码或导航栏按钮控制显示状态

## 开发提示

### 1. 修改 DoSwift 源码

由于使用 dev pods 模式，你可以直接修改 `../Sources/DoSwift/` 目录下的源码文件，然后在 Xcode 中重新构建项目即可看到修改效果。

### 2. 添加新功能

要添加新的调试功能，可以：

1. 在 DoSwift 源码中添加新的插件类
2. 在 AppDelegate.swift 的 `createCustomMenuItems()` 方法中添加对应的菜单项
3. 重新构建项目进行测试

### 3. 自定义菜单

```swift
let customMenuItem = DoSwiftMenuItem(
    identifier: "my_feature",
    title: "我的功能",
    icon: UIImage(systemName: "star")
) { menuItem in
    // 功能实现
    print("执行自定义功能")
}

DoSwiftCore.shared.addMenuItem(customMenuItem)
```

### 4. 推送自定义界面

```swift
let customViewController = MyCustomViewController()
DoSwiftCore.shared.pushViewController(customViewController)
```

## 构建和测试

### 1. 编译项目

在 Xcode 中选择 `DoSwift_Example` target，然后构建运行。

### 2. 测试 dev pods

1. 修改 DoSwift 源码
2. 在 Xcode 中重新构建
3. 验证修改是否生效

### 3. 验证 podspec

```bash
cd ..
pod lib lint DoSwift.podspec --allow-warnings
```

## 常见问题

### 1. Xcode 项目未更新

如果修改了 `project.yml`，需要重新生成项目：

```bash
xcodegen generate
```

### 2. CocoaPods 缓存问题

清理 CocoaPods 缓存：

```bash
pod deintegrate
pod install
```

### 3. 模拟器黑屏

确保在真机或模拟器上都能正常显示悬浮窗，如果遇到问题，检查窗口层级设置。

## 参考资料

- [CocoaPods Dev Pods](https://guides.cocoapods.org/using/the-podfile.html#using-the-files-from-a-folder-local-to-the-machine)
- [XcodeGen 文档](https://github.com/yonaskolb/XcodeGen)
- [DoSwift 主要文档](../README.md)