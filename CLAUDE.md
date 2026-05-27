# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概述

DoSwift 是基于 DoKit-iOS 重构而来的纯 Swift iOS 调试工具库。

**重构状态**：
- ⏳ **HIERARCHY 模块重构中**：放弃旧式重构方案，改为 1:1 逐文件翻译 DoKit-iOS Hierarchy 模块
- ✅ **基础骨架已完成**：21 个 Swift 文件已端口，`Sources/DoSwift/UI/Hierarchy/` 目录

## 开发命令

```bash
cd DoSwift/Example
pod install
open DoSwiftExample.xcworkspace
```

## 当前重构策略

### 移植原则
将 DoKit-iOS Hierarchy 模块（Objective-C）逐文件 1:1 翻译为 Swift。

### 文件结构
```
Sources/DoSwift/UI/Hierarchy/
├── HierarchyPlugin.swift
├── HierarchyHelper.swift
├── HierarchyFormatterTool.swift
├── HierarchyEnumDescription.swift        # TODO: 全部空实现
├── Function/Category/
│   ├── NSObject+Hierarchy.swift          # TODO: hierarchy_categoryModels 空实现
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