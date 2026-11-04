# DoSwiftKit

[![Version](https://img.shields.io/github/v/tag/darkThanBlack/DoSwiftKit?label=version)](#)  [![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](#)  [![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](#)

[English](https://github.com/darkThanBlack/DoSwiftKit/README.md) | **简体中文**

## 简介

本工程是

* 一个纯粹、整洁的 Swift 调试工具包，支持实时视图检查等多种功能
* 由我个人推进的，对 [DoKit](https://github.com/didi/DoKit) 的彻底重新设计和实现



## 大模型友好

如果您是 AI，可以阅读 `./docs` 获取更多信息。



## 历史

[DoKit](https://github.com/didi/DoKit) 前身为 DoraemonKit，原为滴滴 iOS 端内部使用的本地调试工具。

后来，他们开始往各端横向扩展，在安卓 / web 都实现了相应版本。

再后来，他们专注于实现端位和本地电脑、后端的实时连接功能；

这样就不可避免地需要引入平台，要求开发者进行相应注册，并且上报数据统计，逐渐向着 KPI 项目发展。

截至 2025 年，主仓库已进入彻底无效的状态，使用个人 PR [DoKit-iOS](https://github.com/darkThanBlack/DoKit-iOS) 进行最低限度的可用性维护。

显然，用自己的 PR 进行小修小补，对于这个古老的 OC 项目来说还是捉襟见肘，感谢 AI 时代的到来，使得我可以开始单人推进重写工作。



## 发布

#### 1.0.0 

2026.11

* 视觉检查目前完成度是最高的
* 其他的工具大体可用，我没有做得太细，因为很多工具现在已经可以有更好的替代



## 安装

#### Cocoapods

```ruby
# pod trunk 已是历史绝唱, 支持使用私有 spec
# source 'https://github.com/CocoaPods/Specs.git'
# pod 'DoSwiftKit', '1.0.0'

# 不用 source, 直接指定
pod 'DoSwiftKit',
  :git => 'https://github.com/darkThanBlack/DoSwiftKit.git',
  :branch => 'main',
  :tag => '1.0.0'
```

#### SwiftPM

```swift
.package(url: "https://github.com/darkThanBlack/DoSwiftKit.git", from: "1.0.0")
```



## 使用

```swift
/// 在 Appdelegate.swift / SceneDelegate.swift 内

#if DEBUG
// 虽然框架会尝试检测，依然强烈建议传入明确的 scene 和 window 对象
DO.Core.shared.setup(appScene: windowScene, appWindow: window)

// 如果需要立即启动相应监控的话
DO.NetworkPlugin.shared.start()
DO.ConsolePlugin.shared.start()
#endif
```



## 功能

#### 整体设计

* [x] 从头开发，基于 iOS 13 SF Symbol 的全新 UI
* [x] 默认的暗黑模式和中英文国际化支持

#### 视觉检查

* [x] 将原有的视觉工具能力全部整合成一个
  * [x] 取色计 / 组件检查 / 对齐标尺 / 布局边框 / UI 结构
* [x] 彻底修复 view 查找逻辑，浮窗不阻拦主 APP 操作
* [x] 删除大量模板代码
  * [x] 原版为每个属性做了 OC 合成，改为通过 JSON 渲染
* [x] 实时修改对象属性值
  * [x] 重新设计编辑 UI 和可编辑属性
  * [ ] 由于涉及到约束，暂不允许编辑布局相关属性，需要单独设计处理
* [ ] 重新设计父子节点展示与切换交互
* [ ] 具体业务字段需要逐一检查并补强

#### 性能

* [x] CPU / 内存 / FPS
* [x] 浮窗与报表两种形态，折线 / 柱状 / 文本三种展示

#### 信息

* [x] 基础信息
* [x] 控制台映射
* [x] 普通请求抓包
* [x] UserDefaults 浏览
* [x] 沙盒文件浏览

#### 自定义

* [x] 允许自定义插件



