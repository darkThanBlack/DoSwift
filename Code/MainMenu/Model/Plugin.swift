//
//  Plugin.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/20
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {
    
    /// 
    public protocol Plugin {

        var identifier: String { get }

        var title: String { get }

        var icon: UIImage? { get }
        
        /// Call when main menu item did selected.
        var actionHandler: (() -> ())? { get }
    }
    
}
