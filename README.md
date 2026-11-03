# DoSwift

## Intro

[DoKit](https://github.com/didi/DoKit) 前身为 DoraemonKit，原为滴滴 iOS 端内部使用的本地调试工具。

后来得到内部支持，开始往各端横向扩展，并接入所谓平台功能。
截至 2025 年，主仓库已进入彻底无效的状态，使用个人 PR [DoKit-iOS](https://github.com/darkThanBlack/DoKit-iOS) 进行最低限度的可用性维护。

本工程是基于 Swift，借助 AI 能力，由我个人推进的彻底重写：纯 Swift、零第三方依赖、最低 iOS 13。

## 安装

CocoaPods：

```ruby
pod 'DoSwift'
```

SwiftPM：

```swift
.package(url: "https://github.com/darkThanBlack/DoSwift.git", from: "0.1.0")
```

接入后只需在 `#if DEBUG` 里初始化一次：

```swift
DO.Core.shared.setup(appWindow: window)
```

## Feature

#### Mainly

* [x] 从头开发，基于 iOS 13 SF Symbol 的全新 UI
* [x] 插件化：`DO.Plugin` + 默认插件基类，自定义插件接入同一个主菜单

#### UI Hierarchy

* [x] 将原有的视觉工具能力全部整合成一个
  * [x] 取色计 / 组件检查 / 对齐标尺 / 布局边框 / UI 结构
* [x] 彻底修复 view 查找逻辑，浮窗不阻拦主 APP 操作
* [x] 删除大量模板代码
  * [x] 原版为每个属性做了 OC 合成，改为通过 JSON 渲染
* [x] 实时修改对象属性值
  * [x] 编辑 UI 重新设计
  * [x] `layer.*` 这类 key path 只读；其余属性由 JSON 的 `userEditable` 决定
* [ ] 重新设计父子节点展示与切换交互
* [ ] 具体业务字段需要逐一检查并补强

#### Performance

* [x] 将原有的性能工具能力全部整合成一个
  * [x] CPU / 内存 / FPS
  * [x] 浮窗与报表两种形态，折线 / 柱状 / 文本三种展示

#### Info

* [x] App 信息（应用 / 设备 / 权限）
* [x] Console（stdout / stderr / os_log）
* [x] Network（URLSession 抓包）
* [x] UserDefaults
* [x] Sandbox（浏览 / 预览 / 分享 / 复制路径 / 删除）

#### Custom

* [x] 允许自定义插件

## 结构

```
Code/          # 全部源码，命名空间 public enum DO {}
Resources/     # 随包资源（Hierarchy 属性表）
Example/       # CocoaPods dev pod 示例工程
Tests/         # SPM 测试
```

详细说明见 [DEVELOPMENT.md](DEVELOPMENT.md)。
