//
//  HierarchyActionSheet.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/04
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    /// Plain native action sheet. Lives here instead of a `UIViewController` extension so the
    /// library adds no members to UIKit types.
    enum HierarchyActionSheet {

        static func present(
            from presenter: UIViewController,
            title: String,
            actions: [String],
            completion: @escaping (Int) -> Void
        ) {
            guard !actions.isEmpty else { return }

            let sheet = UIAlertController(title: nil, message: title, preferredStyle: .actionSheet)
            for (index, actionTitle) in actions.enumerated() {
                sheet.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
                    completion(index)
                })
            }
            sheet.addAction(UIAlertAction(title: DO.Text.Common.cancel, style: .cancel))

            // Action sheets present in a popover on iPad; without an anchor they raise.
            if let popover = sheet.popoverPresentationController {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(
                    x: presenter.view.bounds.midX,
                    y: presenter.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            presenter.present(sheet, animated: true)
        }
    }
}
