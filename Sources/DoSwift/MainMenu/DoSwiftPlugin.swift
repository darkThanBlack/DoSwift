//
//  DoSwiftPlugin.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/20.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

///
public protocol DoSwiftPlugin {
    
    ///
    var identifier: String { get }
    
    ///
    var title: String { get }
    
    ///
    var icon: UIImage? { get }
    
    ///
    var actionHandler: (() -> ())? { get }
}

///
open class DoSwiftDefaultPlugin: DoSwiftPlugin {
    
    public var identifier: String
    
    public var title: String
    
    public var icon: UIImage?
    
    public lazy var actionHandler: (() -> ())? = { self.show() }
    
    public init(identifier: String, title: String, icon: UIImage? = nil) {
        self.identifier = identifier
        self.title = title
        self.icon = icon
    }
    
    open var window: OverlayWindow?
    
    ///
    open func show() {
        if window == nil {
            let created = makeWindow()
            created.isHidden = true
            window = created
        }
        window?.isHidden = false
    }
    
    ///
    open func hide() {
        window?.isHidden = true
    }
    
    open func makeWindow() -> OverlayWindow {
        fatalError("wrong call, you must override it!")
    }
    
}
