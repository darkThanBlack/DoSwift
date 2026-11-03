//
//  AppInfoAuthority.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
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

extension DO {

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

        private(set) var notification: String? { didSet { if oldValue != notification { onChange?() } } }
        private(set) var cellular: String? { didSet { if oldValue != cellular { onChange?() } } }

        var onChange: (() -> Void)?

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

            Self.queryNotification { [weak self] in self?.notification = $0 }
            cellularData = Self.queryCellular { [weak self] in self?.cellular = $0 }
        }

        func section() -> DO.AppInfoSection? {
            return DO.AppInfoSectionBuilder.make(DO.Text.AppInfo.authoritySection, [
                (DO.Text.AppInfo.location, location),
                (DO.Text.AppInfo.notification, notification),
                (DO.Text.AppInfo.camera, camera),
                (DO.Text.AppInfo.microphone, microphone),
                (DO.Text.AppInfo.photo, photo),
                (DO.Text.AppInfo.contacts, contacts),
                (DO.Text.AppInfo.calendar, calendar),
                (DO.Text.AppInfo.reminder, reminder),
                (DO.Text.AppInfo.bluetooth, bluetooth),
                (DO.Text.AppInfo.tracking, tracking),
                (DO.Text.AppInfo.cellular, cellular),
            ])
        }

        enum State {
            case notDetermined
            case restricted
            case denied
            case granted
            case always
            case whenInUse
            case limited
            case writeOnly
            case unavailable
            case unknown

            var text: String {
                switch self {
                case .notDetermined: return DO.Text.AppInfo.stateNotDetermined
                case .restricted:    return DO.Text.AppInfo.stateRestricted
                case .denied:        return DO.Text.AppInfo.stateDenied
                case .granted:       return DO.Text.AppInfo.stateGranted
                case .always:        return DO.Text.AppInfo.stateAlways
                case .whenInUse:     return DO.Text.AppInfo.stateWhenInUse
                case .limited:       return DO.Text.AppInfo.stateLimited
                case .writeOnly:     return DO.Text.AppInfo.stateWriteOnly
                case .unavailable:   return DO.Text.AppInfo.stateUnavailable
                case .unknown:       return DO.Text.AppInfo.stateUnknown
                }
            }
        }

        private static func locationStatus() -> State {
            guard CLLocationManager.locationServicesEnabled() else { return .unavailable }

            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
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

        private static func photoStatus() -> State {
            let status: PHAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
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

        private static func queryNotification(_ done: @escaping (String) -> Void) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let state: State
                switch settings.authorizationStatus {
                case .notDetermined: state = .notDetermined
                case .denied:        state = .denied
                case .authorized:    state = .granted
                case .provisional:   state = .granted
                default:             state = .unknown
                }
                DispatchQueue.main.async { done(state.text) }
            }
        }

        private static func queryCellular(_ done: @escaping (String) -> Void) -> CTCellularData {
            let data = CTCellularData()
            data.cellularDataRestrictionDidUpdateNotifier = { state in
                let text: String
                switch state {
                case .restricted:    text = DO.Text.AppInfo.cellularRestrictedToWifi
                case .notRestricted: text = DO.Text.AppInfo.cellularUnrestricted
                default:             text = DO.Text.AppInfo.stateUnknown
                }
                DispatchQueue.main.async { done(text) }
            }
            return data
        }
    }
}
