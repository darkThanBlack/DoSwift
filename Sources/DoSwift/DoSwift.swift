//
//  DoSwift.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import Foundation
import UIKit

/// DoSwift 主要命名空间
public enum DoSwift {}

// MARK: - Core Extension

extension DoSwift {

    /// DoSwift 核心接口
    public enum Core {}

    /// DoSwift UI 组件
    public enum UI {}

    /// DoSwift 插件系统
    public enum Plugin {}
}

// MARK: - Protocols

/// DoSwift 组件协议
public protocol DoSwiftComponent: AnyObject {
    var isEnabled: Bool { get set }
    func start()
    func stop()
}

/// DoSwift 插件协议
public protocol DoSwiftPlugin: DoSwiftComponent {
    var identifier: String { get }
    var name: String { get }
    var version: String { get }
}