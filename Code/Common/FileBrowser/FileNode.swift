//
//  FileNode.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/02
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    // MARK: - Node contract

    /// Minimum the path bar needs: a display name. No id — identity stays in the business
    /// model, which the browser hands back untouched for you to cast.
    protocol PathNode {

        /// nil or empty = nothing to show (path bar draws a placeholder, the row hides it).
        var nodeName: String? { get }
    }

    /// Node kind
    enum FileNodeKind: Equatable {

        /// Folder: can be entered.
        case folder

        /// File: can be opened; preview / share is up to the business.
        case file
    }

    /// What one row needs. Read-only — UI state never flows back into the model.
    protocol FileNode: DO.PathNode {

        var nodeKind: DO.FileNodeKind { get }

        /// Size in bytes; usually nil for folders.
        var nodeSize: Int64? { get }

        /// Icon token; the default treats it as an SF Symbol name.
        var nodeIconToken: String? { get }
    }
}

extension DO.FileNode {

    var nodeSize: Int64? { return nil }

    var nodeIconToken: String? { return nil }
}
