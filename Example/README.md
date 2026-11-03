# DoSwift Example

最小可运行的宿主工程，用 CocoaPods dev pod 直接引用仓库根目录的源码。

## 结构

```
Example/
├── Example/
│   ├── AppDelegate.swift        # 建 window，DEBUG 下 setup
│   ├── Info.plist
│   └── LaunchScreen.storyboard
├── Podfile                      # pod 'DoSwift', :path => '../'
├── Podfile.lock
├── project.yml                  # XcodeGen 配置
└── README.md
```

## 跑起来

```bash
cd Example
xcodegen generate     # 只有改了 project.yml 才需要，.xcodeproj 不入库
pod install
open DoSwiftExample.xcworkspace
```

## dev pod

`Podfile` 用 `:path => '../'` 指向仓库根目录，CocoaPods 按 `DoSwift.podspec` 里的
`source_files`（`Code/**`）和 `resource_bundles`（`Resources/**`）组织编译。

改 `Code/` 下的源码后直接重新构建即可，不需要重新 `pod install`；只有改了 podspec 或
增删文件导致 glob 结果变化时，才需要 `pod install` 一次。

## 入口

`AppDelegate` 里只做一件事：

```swift
#if DEBUG
DO.Core.shared.setup(appWindow: window)
#endif
```

`appWindow` 建议显式传入 —— 自动探测 `keyWindow` 只是兜底，多 scene 场景下不保证准确。
需要挂自定义工具时传 `plugins:`：

```swift
DO.Core.shared.setup(appWindow: window, plugins: [MyPlugin()])
```

## 注意

`project.yml` 里 `platform: [iOS]` 是数组形式，XcodeGen 默认会派生出 `<name>_iOS` 的 target 名，
所以显式写了 `platformSuffix: ""` 保住 `DoSwift_Example`，否则 Podfile / scheme 里的名字对不上。
