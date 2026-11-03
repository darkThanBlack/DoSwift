//
//  DefaultPlugin.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/2
//
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//


import UIKit

extension DO {
    
    /// Base plugin for driftable window.
    open class DefaultPlugin: DO.Plugin {
        
        public var identifier: String
        
        public var title: String
        
        public var icon: UIImage?
        
        public lazy var actionHandler: (() -> ())? = { self.show() }
        
        public init(identifier: String, title: String, icon: UIImage? = nil) {
            self.identifier = identifier
            self.title = title
            self.icon = icon
        }
        
        open private(set) var window: DO.OverlayWindow?
        
        /// Sub class must override it. Call when window is nil.
        open func makeWindow() -> DO.OverlayWindow {
            fatalError("wrong call, you must override it!")
        }
        
        open func show() {
            if window == nil {
                window = makeWindow()
            }
            window?.isHidden = false
        }
        
        open func hide() {
            window?.isHidden = true
        }
        
    }
    
}
