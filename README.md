# DoSwift



## Intro

[DoKit](https://github.com/didi/DoKit) 前身为 DoraemonKit，原为滴滴 iOS 端位内部使用的本地调试工具。

后来得到内部支持，开始往各端位横向扩展，并接入所谓平台功能。

截至 2025 年，注意到主仓库已进入彻底无效的状态，使用个人 PR [DoKit-iOS](https://github.com/darkThanBlack/DoKit-iOS) 进行最低限度的可用性维护。

本工程是基于 Swift，借助 AI 能力，由我个人推进的彻底重写。



## Feature

#### Mainly

* [x] 从头开发，基于 iOS 13 SF Symbol 的全新 UI

#### UI Hierarchy

* [x] 将原有的视觉工具能力全部整合成一个
  * [x] 取色计 / 组件检查 / 对齐标尺 / 布局边框 / UI 结构
* [x] 彻底修复 view 查找逻辑，浮窗不阻拦主 APP 操作
* [x] 删除大量模板代码
  * [x] 原版为每个属性做了 OC 合成，改为通过 json 渲染
* [x] 实时修改对象属性值
  * [x] 编辑 UI 重新设计
  * [ ] 暂不允许编辑布局类属性（frame / center / layer.*），需要额外处理约束相关属性的展示和编辑
* [ ] 重新设计父子节点展示与切换交互
* [ ] 具体业务字段需要逐一检查并补强

#### Pref

* [x] 将原有的性能工具能力全部整合成一个
  * [x] CPU / 内存 / FPS

#### Info

* [x] Basic
* [x] NSLog
* [x] UserDefaults
* [x] Sandbox

#### Custom

* [x] 允许自定义插件
