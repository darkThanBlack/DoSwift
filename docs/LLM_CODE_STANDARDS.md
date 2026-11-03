# LLM 代码规范指南

基于 XiaoMai s 工程的成熟 iOS 架构实践，为 LLM 辅助开发制定的代码规范和架构指导。

## 目录结构和模块化设计

### 1. 多层次模块架构
```
Project/
├── Basic/           # 基础框架模块
│   ├── Interface/   # 协议定义和服务接口
│   ├── UIKit/      # UI 基础组件和扩展
│   ├── Foundation/ # Foundation 框架扩展
│   └── Support/    # 配置和工具类
├── Business/       # 业务模块 (如 Sport)
│   ├── Base/       # 基础业务类
│   ├── Manager/    # 管理器类
│   ├── UIKit/      # 业务 UI 组件
│   └── Navigate/   # 导航相关
└── Network/        # 网络模块 (如 SportNet)
    ├── Base/       # 网络基类
    ├── JSBridge/   # JS 桥接
    └── Upload/     # 上传相关
```

### 2. CocoaPods 模块化配置
```ruby
# 使用 subspec 进行模块细分
s.subspec 'Basic' do |ss|
    ss.source_files = 'XMKit/Basic/**/*'
    ss.dependency 'DTBKit/Core'
end

s.subspec 'Business' do |ss|
    ss.dependency 'XMKit/Basic'
    ss.dependency 'RxSwift', '6.6.0'
    ss.dependency 'SnapKit', '5.6.0'
end
```

## 命名空间和扩展规范

### 3. 全局命名空间模式
```swift
// 使用统一命名空间避免命名冲突
public typealias XM = DTBKit.DTB

extension Kitable {
    public var xm: Wrapper<Self> { return dtb }
    public static var xm: StaticWrapper<Self> { return dtb }
}

// 使用示例
let color = UIColor.xm.create(hex: "#FF0000")
let frame = view.xm.centerInSuperview()
```

### 4. 扩展组织规范
```swift
// 按功能分组扩展，使用 MARK 注释
extension UIView {

    // MARK: - Frame Helpers
    func centerInSuperview() -> CGRect { /* */ }

    // MARK: - Animation Helpers
    func fadeIn(duration: TimeInterval) { /* */ }
}

// 文件命名：UIView+Basic.swift, UIColor+Business.swift
```

## 类和协议设计规范

### 5. 命名规范
```swift
// 类名：业务前缀 + 功能描述 + 类型
class SportBaseViewController: UIViewController {}
class HomeViewModel: SportBaseViewModel {}
class FileManager: NSObject {}

// 协议名：功能描述 + Type/Provider 后缀
protocol ColorProvider {}
protocol FastNavigationType {}
protocol ProviderRegister {}

// 方法名：动词开头，描述性强
func queryShortcuts() -> Promise<[AllShortcutsVM]>
func reloadStudios() -> Promise<Void>
func registerProvider<T>(_ value: T?, key: XM.ConstKey<T>)

// 属性名：名词性，明确含义
private let viewModel = HomeViewModel()
private var isReloading = false
public let navigationView = XMKit.NavigationView()
```

### 6. 访问控制规范
```swift
// 优先级：private > fileprivate > internal > public
// 默认不写访问控制符 = internal

// 私有实现
private let bag = DisposeBag()
private func setupUI() {}

// 模块内共享
fileprivate struct MainVO {}

// 对外接口
public protocol ProviderRegister {}
public static let shared = Configuration()

// 开放继承 (谨慎使用)
open class SportBaseViewController: UIViewController {}
open var navigationTheme: NavigationView.Themes = .pure
```

## 架构模式和设计模式

### 7. MVVM 架构规范
```swift
// ViewController：负责 UI 展示和用户交互
class HomeViewController: SportBaseViewController {
    private let viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func bindViewModel() {
        // RxSwift 绑定
    }
}

// ViewModel：负责业务逻辑和数据处理
class HomeViewModel: SportBaseViewModel {
    func queryShortcuts() -> Promise<[AllShortcutsVM]> {
        return provider.request(.shortcuts)
            .map(AllShortcutsVO.self)
            .map { $0.data?.compactMap(AllShortcutsVM.init) ?? [] }
    }
}

// 基类设计
open class SportBaseViewController: UIViewController, FastNavigations {
    // 通用功能实现
}

open class SportBaseViewModel {
    public let provider = SportProvider()
    public let bag = DisposeBag()
}
```

### 8. 服务定位器模式（依赖注入）
```swift
// 协议定义
public protocol ProviderRegister {
    static func registerProvider<T>(_ value: T?, key: XM.ConstKey<T>)
}

// 服务注册
extension XM {
    public enum BasicInterface: ProviderRegister {
        public static let colorKey = XM.ConstKey<any ColorProvider>("basic.service.color")
        public static let hudKey = XM.ConstKey<any HUDProvider>("basic.service.hud")
    }
}

// 类型安全的键管理
extension XM {
    public struct ConstKey<T> {
        let key_: String
        let useLock_: Bool

        public init(_ key: String, useLock: Bool = true) {
            self.key_ = key
            self.useLock_ = useLock
        }
    }
}

// 服务使用
let colorProvider: ColorProvider = XM.app.get(XM.BasicInterface.colorKey)
```

## 异步编程和错误处理

### 9. Promise + RxSwift 异步模式
```swift
// Promise 链式调用
func reloadData() -> Promise<Void> {
    return when(fulfilled: [
        reloadStudios(),
        reloadNavButtons(),
        reloadMetrics()
    ]).done { _ in
        // 全部完成后的处理
    }.catch { error in
        self.handleError(error)
    }.finally {
        self.hideLoading()
    }
}

// RxSwift Observable 处理
viewModel.shortcuts
    .observe(on: MainScheduler.instance)
    .bind(to: tableView.rx.items) { tableView, index, item in
        // 绑定数据到 UI
    }
    .disposed(by: bag)
```

### 10. 统一错误处理模式
```swift
// 自定义错误扩展
extension NSError {
    static func xm.create(_ message: String, code: Int = -1) -> NSError {
        return NSError(domain: "XMKit", code: code, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
}

// Promise 错误处理
.catch { error in
    if error.localizedDescription.count > 0 {
        self.view.xm.toast(error.localizedDescription)
    }
}

// 业务层错误包装
completion?(.failure(NSError.xm.create(vo.message, code: code)))
```

## UI 组件和布局规范

### 11. 协议驱动的组件设计
```swift
// 组件协议定义
public protocol FastNavigationType: UIView {
    associatedtype Themes
    associatedtype LeftStyles
    associatedtype RightStyles

    var fastLeftHandler: (() -> Void)? { get set }

    func fastUpdate(title: String?, theme: Themes, leftStyle: LeftStyles, rightStyle: RightStyles?)
}

// 具体实现
public class NavigationView: UIView, FastNavigationType {
    public enum Themes { case pure, gradient }
    public enum LeftStyles { case back, close, none }
    public enum RightStyles { case text(String), image(UIImage), none }

    public var fastLeftHandler: (() -> Void)?
}
```

### 12. 链式调用和声明式 UI
```swift
// 支持链式配置的扩展
private lazy var backgroundImageView = UIImageView().xm
    .image(UIImage(named: "background01"))
    .contentMode(.scaleToFill)
    .value

// 布局扩展
view.xm
    .addSubview(navigationView)
    .layout { make in
        make.top.leading.trailing.equalToSuperview()
        make.height.equalTo(88)
    }
```

## 资源管理和配置

### 13. 类型安全的配置管理
```swift
// 全局配置类
extension XM {
    public final class Configuration {
        public static let shared = XM.Configuration()
        private init() {}

        var designBaseSize = CGSize(width: 375.0, height: 667.0)
        var supportImageTypes = ["png", "jpg", "webp", "jpeg"]

        public func updateDesignBaseSize(_ value: CGSize) {
            self.designBaseSize = value
        }
    }
}
```

### 14. 内存管理和缓存策略
```swift
// 应用级管理器
public final class AppManager {
    public static let shared = AppManager()
    private init() {}

    // 强引用缓存
    private var memory: [String: Any] = [:]

    // 弱引用缓存
    private var weakMemory: [String: XM.Weaker<AnyObject>] = [:]

    private let mLock = NSLock()

    public func set<T>(_ value: T?, key: XM.ConstKey<T>) {
        // 线程安全的设置
    }

    public func get<T>(_ key: XM.ConstKey<T>) -> T? {
        // 线程安全的获取
    }
}
```

## 文档和注释规范

### 15. 文档注释规范
```swift
/// 导航栏页面默认实现
///
/// 提供统一的导航栏交互模式，支持主题切换和自定义按钮
public protocol FastNavigationType: UIView {

    /// 主题枚举，用于控制导航栏样式
    associatedtype Themes

    /// 左侧单个按钮事件回调
    ///
    /// - Warning: 注意赋值时机，应在 viewDidLoad 后设置
    var fastLeftHandler: (() -> Void)? { get set }

    /// 更新导航栏配置
    ///
    /// - Parameters:
    ///   - title: 标题文本
    ///   - theme: 主题样式
    ///   - leftStyle: 左侧按钮样式
    ///   - rightStyle: 右侧按钮样式
    func fastUpdate(title: String?, theme: Themes, leftStyle: LeftStyles, rightStyle: RightStyles?)
}
```

### 16. 代码注释规范
```swift
// MARK: - Life Cycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindViewModel()
}

// MARK: - UI Setup
private func setupUI() {
    // 背景设置
    view.backgroundColor = .white

    // 导航栏配置
    navigationView.fastUpdate(
        title: "首页",
        theme: .pure,
        leftStyle: .none,
        rightStyle: .none
    )
}

// MARK: - Private Methods
/// 处理网络请求错误
private func handleError(_ error: Error) {
    // 错误处理逻辑
}
```

## 测试和质量保证

### 17. 单元测试规范
```swift
// 测试文件命名：ModuleNameTests.swift
class StringTests: XCTestCase {

    func testEmailValidation() {
        // Given
        let validEmail = "test@example.com"
        let invalidEmail = "invalid-email"

        // When & Then
        XCTAssertTrue(validEmail.xm.isValidEmail)
        XCTAssertFalse(invalidEmail.xm.isValidEmail)
    }
}

// testspecs 配置
pod 'XMKit/Basic', :path => 'XMKit', :testspecs => ['Tests']
```

### 18. 代码质量检查清单
```swift
// ✅ 检查项目
// 1. 访问控制：是否正确使用 private/fileprivate/public
// 2. 命名规范：类名、方法名、属性名是否符合规范
// 3. 文档注释：公开接口是否有完整文档
// 4. 错误处理：是否正确处理可能的异常情况
// 5. 内存管理：是否存在循环引用或内存泄漏
// 6. 线程安全：多线程访问的代码是否线程安全
// 7. 模块依赖：是否存在循环依赖或不必要的依赖
```

---

## 核心原则总结

1. **模块化优先**：使用 CocoaPods subspec 进行清晰的模块划分
2. **协议驱动**：大量使用协议定义接口，支持依赖注入和测试
3. **命名空间**：使用统一命名空间避免冲突，提升可维护性
4. **类型安全**：利用 Swift 泛型和类型系统确保编译时安全
5. **响应式编程**：RxSwift + PromiseKit 处理异步操作和数据流
6. **链式调用**：支持声明式的 UI 配置和链式方法调用
7. **文档完整**：重要接口必须有完整的文档注释
8. **测试覆盖**：核心模块必须有对应的单元测试

此规范基于成熟的企业级 iOS 应用架构实践，适用于中大型项目的开发和维护。