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

* [x] 将原有的视觉工具（取色计 / 组件检查 / 对齐标尺 / 布局边框 / UI 结构）全部整合成一个
* [x] 使用工具的同时可以直接操作主 APP
* [x] 彻底修复 view 查找逻辑，删除绝大多数模板代码，改为 json 配置渲染
* [ ] 具体字段需要逐一检查并补强
* [ ] 实时修改对象属性功能尚未实现
* [ ] 父子节点展示与切换交互需要重新设计

