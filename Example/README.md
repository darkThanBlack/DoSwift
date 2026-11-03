# DoSwift Example

最小可运行的宿主工程，用 CocoaPods dev pod 直接引用仓库根目录的源码。

## 结构

```
Example/
├── Example/
│   ├── AppDelegate.swift        # 只有 didFinishLaunching
│   ├── SceneDelegate.swift      # 建 window，DEBUG 下 setup
│   ├── Info.plist               # UIApplicationSceneManifest 单 scene
│   └── LaunchScreen.storyboard
├── Podfile                      # pod 'DoSwiftKit', :path => '../'
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

**顺序不能反**：`xcodegen generate` 是整份重写 `.xcodeproj`，会把 `pod install` 写进去的
xcconfig / Pods 链接一起抹掉，表现为 `Unable to find module dependency: 'DoSwift'`。
先 generate、后 install。

## dev pod

`Podfile` 用 `:path => '../'` 指向仓库根目录，CocoaPods 按 `DoSwiftKit.podspec` 里的
`source_files`（`Code/**`）和 `resource_bundles`（`Resources/**`）组织编译。

改 `Code/` 下的源码后直接重新构建即可，不需要重新 `pod install`；只有改了 podspec 或
增删文件导致 glob 结果变化时，才需要 `pod install` 一次。

## 入口

这是单 scene 的 `UIWindowScene` 工程：window 在 `SceneDelegate` 里建，工具也在那里启动。

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = root
    window.makeKeyAndVisible()
    self.window = window

    #if DEBUG
    DO.Core.shared.setup(appWindow: window, appScene: windowScene)
    #endif
}
```

- `appScene` 决定所有浮窗挂到哪个 `UIWindowScene`；只传 window 时会取它的 `windowScene`
- 两者都不传也能跑，但走的是「按前台 scene 猜 + `keyWindow`」的兜底分支，多 scene 下不保证准确
- 需要挂自定义工具时传 `plugins:`：

```swift
DO.Core.shared.setup(appWindow: window, appScene: windowScene, plugins: [MyPlugin()])
```

## 注意

`project.yml` 里 `platform: [iOS]` 是数组形式，XcodeGen 默认会派生出 `<name>_iOS` 的 target 名，
所以显式写了 `platformSuffix: ""` 保住 `DoSwift_Example`，否则 Podfile / scheme 里的名字对不上。
