//
//  AppInfoAuthority.swift
//  DoSwift
//

import UIKit
import CoreLocation
import AVFoundation
import Photos
import Contacts
import EventKit
import CoreBluetooth
import CoreTelephony
import UserNotifications
import AppTrackingTransparency

/// 「权限」组。
///
/// 这一组是四组里**唯一有异步状态**的：通知与蜂窝两项系统只能回调式给值，所以类里存着
/// 它们的当前值，`reload()` 只发起查询，结果回来自己写进属性、再响一声 `onChange`。
/// 同步的那九项照同一个形状存——一视同仁，外层看不到差别。
///
/// **只读不请求**：`authorizationStatus` 这一类查询不弹窗、不需要 `Info.plist` 里的
/// 用途说明，也不改变任何东西——本页是面板，不是请求入口。
final class AppInfoAuthority {

    private(set) var location: String?
    private(set) var camera: String?
    private(set) var microphone: String?
    private(set) var photo: String?
    private(set) var contacts: String?
    private(set) var calendar: String?
    private(set) var reminder: String?
    private(set) var bluetooth: String?
    private(set) var tracking: String?

    /// 通知与蜂窝：初值 nil（= 这一行不显示），回调到了才有值。
    ///
    /// 写入时若值没变就不响——重开页面时这两项会拿到相同的答案，不必白刷一次表。
    private(set) var notification: String? { didSet { if oldValue != notification { onChange?() } } }
    private(set) var cellular: String? { didSet { if oldValue != cellular { onChange?() } } }

    /// 有异步值落盘了。**不分字段**，谁变都响这一声。
    var onChange: (() -> Void)?

    /// 蜂窝那条路只能靠回调，`CTCellularData` 一释放回调就没了，所以得持有。
    private var cellularData: CTCellularData?

    func reload() {
        location = Self.locationStatus().text
        camera = Self.cameraStatus().text
        microphone = Self.microphoneStatus().text
        photo = Self.photoStatus().text
        contacts = Self.contactsStatus().text
        calendar = Self.eventKitStatus(.event).text
        reminder = Self.eventKitStatus(.reminder).text
        bluetooth = Self.bluetoothStatus().text
        tracking = Self.trackingStatus().text

        // 这两个**不复位**：保留上次的值，新值到了再响一声。复位会让每次开页都闪一下。
        Self.queryNotification { [weak self] in self?.notification = $0 }
        cellularData = Self.queryCellular { [weak self] in self?.cellular = $0 }
    }

    func section() -> DoSwiftAppInfoSection? {
        return AppInfoSection.make("权限", [
            ("地理位置", location),
            ("通知", notification),
            ("相机", camera),
            ("麦克风", microphone),
            ("相册", photo),
            ("通讯录", contacts),
            ("日历", calendar),
            ("提醒事项", reminder),
            ("蓝牙", bluetooth),
            ("跟踪", tracking),
            ("蜂窝数据", cellular),
        ])
    }

    // MARK: - 状态词汇

    /// 归一化之后的授权状态。
    ///
    /// 系统各框架的词汇并不统一：相册 iOS 14 起多了 `.limited`（部分照片），
    /// 日历/提醒事项 iOS 17 起把 `.authorized` 拆成「全部」与「仅写入」，
    /// 定位多一维「始终 / 使用期间」，ATT 与 CoreBluetooth 又只有四态。
    /// 这里统一成一套，全组共用同一份文案。
    enum State {
        case notDetermined
        case restricted
        case denied
        case granted
        case always         // 定位特有
        case whenInUse      // 定位特有
        case limited        // 相册 / 通讯录特有
        case writeOnly      // 日历 / 提醒事项特有
        case unavailable    // 这台设备 / 这个系统版本上就没有这项能力
        case unknown

        var text: String {
            switch self {
            case .notDetermined: return "未决定"
            case .restricted:    return "受限"
            case .denied:        return "已拒绝"
            case .granted:       return "已授权"
            case .always:        return "始终允许"
            case .whenInUse:     return "使用期间"
            case .limited:       return "部分授权"
            case .writeOnly:     return "仅写入"
            case .unavailable:   return "不适用"
            case .unknown:       return "未知"
            }
        }
    }

    // MARK: - 同步取值

    /// 定位。
    ///
    /// 先看系统总开关：总开关关掉时 `authorizationStatus` 会报成 `.denied`，
    /// 那会让人以为是自己拒过——实际是「定位服务整个关了」，两回事，所以分开报。
    private static func locationStatus() -> State {
        guard CLLocationManager.locationServicesEnabled() else { return .unavailable }

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            // 类方法 `+authorizationStatus` 自 iOS 14 起废弃，实例属性是唯一正路
            status = CLLocationManager().authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .notDetermined:       return .notDetermined
        case .restricted:          return .restricted
        case .denied:              return .denied
        case .authorizedAlways:    return .always
        case .authorizedWhenInUse: return .whenInUse
        @unknown default:          return .unknown
        }
    }

    private static func cameraStatus() -> State {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .authorized:    return .granted
        @unknown default:    return .unknown
        }
    }

    /// 麦克风。
    ///
    /// iOS 17 起官方口径从 `AVAudioSession.recordPermission` 移到了
    /// `AVAudioApplication.recordPermission`（前者已标废弃），两边读的是同一条 TCC 记录。
    private static func microphoneStatus() -> State {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined: return .notDetermined
            case .denied:       return .denied
            case .granted:      return .granted
            @unknown default:   return .unknown
            }
        }

        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined: return .notDetermined
        case .denied:       return .denied
        case .granted:      return .granted
        @unknown default:   return .unknown
        }
    }

    /// 相册。iOS 14 起按访问级别分（读写 / 只增），这里报「读写」那一档
    /// ——它才是「App 能不能看到你的照片」。
    private static func photoStatus() -> State {
        let status: PHAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            // `.limited` 只在 iOS 14 之后存在，引用它必须关在可用性判断里
            if status == .limited { return .limited }
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .authorized:    return .granted
        default:             return .unknown
        }
    }

    /// 通讯录。iOS 18 起多了 `.limited`（只授权了部分联系人）。
    private static func contactsStatus() -> State {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if #available(iOS 18.0, *), status == .limited { return .limited }

        switch status {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .authorized:    return .granted
        default:             return .unknown
        }
    }

    private static func eventKitStatus(_ type: EKEntityType) -> State {
        let status = EKEventStore.authorizationStatus(for: type)

        // iOS 17 把 `.authorized` 拆成「全部」与「仅写入」两档
        // （`.authorized` 本身保留为 `.fullAccess` 的别名）
        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess: return .granted
            case .writeOnly:  return .writeOnly
            default:          break
            }
        }

        switch status {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .authorized:    return .granted
        default:             return .unknown
        }
    }

    /// 蓝牙。
    ///
    /// 原版 DoKit 这一项直接 `return @""`（压根没做）。现代反而好做：CoreBluetooth 自
    /// iOS 13.1 起给了类属性 `CBManager.authorization`，**不必实例化 `CBCentralManager`
    /// 就能读**，也就不会触发配对或权限弹窗。
    private static func bluetoothStatus() -> State {
        guard #available(iOS 13.1, *) else { return .unavailable }

        switch CBManager.authorization {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .allowedAlways: return .granted
        @unknown default:    return .unknown
        }
    }

    /// 广告跟踪（ATT）。
    ///
    /// 读状态**不会**弹 ATT 弹窗——弹窗只由 `requestTrackingAuthorization` 触发。
    /// iOS 14 以下没有这项能力，报「不适用」而不是「未决定」。
    private static func trackingStatus() -> State {
        guard #available(iOS 14.0, *) else { return .unavailable }

        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        case .denied:        return .denied
        case .authorized:    return .granted
        @unknown default:    return .unknown
        }
    }

    // MARK: - 异步取值

    /// 通知授权。
    ///
    /// 原版用的是 `UIApplication.currentUserNotificationSettings`，那个在 iOS 10 就废弃了。
    /// 现在唯一的路是 `UNUserNotificationCenter.getNotificationSettings`，**回调式**。
    private static func queryNotification(_ done: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let state: State
            switch settings.authorizationStatus {
            case .notDetermined: state = .notDetermined
            case .denied:        state = .denied
            case .authorized:    state = .granted
            case .provisional:   state = .granted   // 临时授权：通知能到，但没弹过窗
            default:             state = .unknown   // 含 iOS 14 的 .ephemeral（App Clip 专用）
            }
            DispatchQueue.main.async { done(state.text) }
        }
    }

    /// 蜂窝数据是否对本 App 受限。
    ///
    /// 两点要说清楚：
    /// 1. **它不是权限**。它答的是「设置里这个 App 的『无线局域网与蜂窝数据』有没有被关掉」，
    ///    跟 TCC 授权不是一回事——所以这一行叫「蜂窝数据」，不叫「网络权限」。
    /// 2. 值**只能从回调里拿**：`restrictedState` 在设回调之前是未知的，头文件写明
    ///    「第一次设置回调时会派发一次」，所以必须设回调、必须等。
    private static func queryCellular(_ done: @escaping (String) -> Void) -> CTCellularData {
        let data = CTCellularData()
        // 回调在全局队列上派发，回主线程再说
        data.cellularDataRestrictionDidUpdateNotifier = { state in
            let text: String
            switch state {
            case .restricted:    text = "受限（仅 Wi-Fi）"
            case .notRestricted: text = "不受限"
            default:             text = "未知"
            }
            DispatchQueue.main.async { done(text) }
        }
        return data
    }
}
