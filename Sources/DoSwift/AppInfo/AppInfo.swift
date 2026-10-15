//
//  AppInfo.swift
//  DoSwift
//

import UIKit
import QuickLook

/// 「App 信息」的全部数据。
///
/// 四组各管自己那一摊（设备 / 应用 / 运行时 / 权限），本类只做两件事：
/// **按顺序 reload、按顺序拼**。页面只跟它打交道，不认识那四个对象。
///
/// **值是存的，不是算的**：所有字段都声明成 `String?`、默认 nil，由 `reload()` 统一赋值，
/// 异步的那两个等回调回来自己写进去。这不是风格取舍，三个理由都是实的：
///
/// 1. 同步和异步变成同一个形状——「哪一行要等」这件事在数据层不存在了。
/// 2. `sections()` 是纯读，可以随 `onChange` 反复调，不会重跑系统调用。
/// 3. `uname` / `getifaddrs` / 各项授权查询开页只跑一次，不随重绘重跑。
///
/// 代价是**必须显式调一次 `reload()`**，否则整页空白；以及**取不到的字段保留上一次的值**
/// （刻意不重置回 nil，第二次打开才不会闪）。
final class AppInfo {

    static let shared = AppInfo()

    private let device = AppInfoDevice()
    private let application = AppInfoApplication()
    private let runtime = AppInfoRuntime()
    private let authority = AppInfoAuthority()

    /// 有组异步写完了值。
    ///
    /// **不分字段**——谁变都响这一声，外层因此不必知道是哪一个、更不必知道它什么时候变，
    /// 只需要在这一声里把自己重画一遍。
    var onChange: (() -> Void)?

    private init() {
        // 目前只有权限那组有异步来源；将来别组有了，在这里接上即可
        authority.onChange = { [weak self] in self?.onChange?() }
    }

    /// 重取一遍全部字段。由页面在开页时**显式**调用。
    func reload() {
        device.reload()
        application.reload()
        runtime.reload()
        authority.reload()
    }

    /// 按展示顺序拼起来。顺序就在这四行里，别处没有第二份。
    func sections() -> [DoSwiftAppInfoSection] {
        return [device.section(), application.section(), runtime.section(), authority.section()]
            .compactMap { $0 }
    }
}
