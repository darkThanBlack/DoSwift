# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概述

DoSwift 是基于 DoKit-iOS 重构而来的纯 Swift iOS 调试工具库。

**重构状态**：
- ⏳ **HIERARCHY 模块重构中**：UI 骨架逐文件翻译，属性清单改为 JSON 数据驱动（见下）
- ✅ **属性检查器已数据化**：属性清单 + 枚举描述声明在 `HierarchyProperties.json`，由 `HierarchyPropertyEngine` 通过 KVC 反射只读渲染；回填（编辑）延后

## 开发命令

```bash
cd DoSwift/Example
pod install
open DoSwiftExample.xcworkspace
```

## 当前重构策略

### 属性检查器：JSON 数据驱动（替代 1:1 翻译）
原版 DoKit-iOS 的「每个控件暴露哪些属性 + 枚举映射」是几千行重复硬编码
（`NSObject+DoraemonHierarchy.m` 2527 行、`DoraemonEnumDescription.m` 880 行）。
为减少 Swift 代码，这一部分改为数据驱动：

- **`HierarchyProperties.json`**：唯一数据源，信封结构
  - `types`：每个类（`NSObject`/`UIView`/`UILabel`/…）暴露的 `groups`，每条 `item` 声明 `key`/`editor`/`title`/`enumType` 等元数据
  - `enums`：`{ value, name }[]` 有序数组，同时推导描述表与顺序表
- **`HierarchyPropertyEngine.swift`**：只读渲染骨架，按 `classChain(view)` 匹配条目，
  用 KVC（`value(forKeyPath:)`）反射读取并生成 `HierarchyCategoryModel`/`HierarchyCellModel`
- **回填（编辑）延后**：所有 `show*Alert`/`setBlock`/`changePropertyBlock` 已移除，UI 只读

数据驱动的取舍（已知、可接受）：
- 丢编译期类型检查 → 枚举 rawValue 是裸 int，靠 JSON 里相邻的 `name` 自解释
- KVC 边界：纯 Swift 自定义视图（非 `@objc`）的属性读不到，只显示到父类层（与原版 ObjC 同限）

### UI 骨架：仍逐文件翻译
除上述属性清单外，窗口/控制器/视图/Cell 等骨架仍按 DoKit-iOS 逐文件 1:1 翻译为 Swift。

### 文件结构
```
Sources/DoSwift/UI/Hierarchy/
├── HierarchyPlugin.swift
├── HierarchyHelper.swift
├── HierarchyFormatterTool.swift
├── HierarchyPropertyEngine.swift        # JSON 驱动只读渲染引擎
├── HierarchyProperties.json             # 属性清单 + 枚举描述（唯一数据源）
├── Function/Category/
│   ├── NSObject+Hierarchy.swift          # TODO: hierarchy_categoryModels 空实现（被引擎取代，待删）
│   ├── UIColor+Hierarchy.swift
│   └── UIViewController+Hierarchy.swift
└── UserInterface/
    ├── HierarchyWindow.swift
    ├── HierarchyViewController.swift
    ├── HierarchyTableViewController.swift
    ├── HierarchyDetailViewController.swift
    ├── Model/
    │   ├── HierarchyCategoryModel.swift
    │   └── HierarchyCellModel.swift
    ├── View/
    │   ├── MoveView.swift
    │   ├── PickerView.swift
    │   ├── HierarchyPickerView.swift
    │   ├── HierarchyInfoView.swift
    │   └── HierarchyHeaderView.swift
    └── Cell/
        └── HierarchyCellModels.swift
```

### 原 DoKit-iOS 源码路径
```
/Users/admin/Documents/github/DoKit-iOS/iOS/DoraemonKit/Src/Core/Plugin/UI/Hierarchy/
```

### 增量翻译流程
1. 桩代码策略：依赖尚未翻译的方法用 `// TODO` 空实现标记
2. 每批完成后不编译，由用户手动编译验证
3. 禁止使用 NSInvocation（Swift 不支持），需要时使用 ObjC 桥接文件
4. JSON 配置经 `DoSwift.podspec` 的 `resource_bundles` 打包，引擎按 main/framework/resource bundle 三级查找