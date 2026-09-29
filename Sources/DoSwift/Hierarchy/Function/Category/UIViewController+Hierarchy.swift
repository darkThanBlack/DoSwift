//
//  UIViewController+Hierarchy.swift
//  DoSwift
//
//  Translated from UIViewController+DoraemonHierarchy.m
//

import UIKit

extension UIViewController {

    /// 递归查找当前正在展示的 ViewController
    var hierarchy_currentShowingViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.hierarchy_currentShowingViewController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.hierarchy_currentShowingViewController
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.hierarchy_currentShowingViewController
        }
        return self
    }

    /// 弹出确认对话框
    func hierarchy_showAlert(message: String, handler: ((Int) -> Void)?) {
        let alert = UIAlertController(title: "Note", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in handler?(0) })
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in handler?(1) })
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    /// 弹出 ActionSheet 选择器
    func hierarchy_showActionSheet(title: String, actions: [String], currentAction: String?, completion: ((Int) -> Void)?) {
        let alert = UIAlertController(title: nil, message: title, preferredStyle: .actionSheet)
        for (index, actionTitle) in actions.enumerated() {
            let action = UIAlertAction(title: actionTitle, style: .default) { _ in
                completion?(index)
            }
            if let current = currentAction, actionTitle == current {
                action.isEnabled = false
                // TODO: set checkmark image via KVC
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    /// 弹出文本输入框
    func hierarchy_showTextFieldAlert(message: String, text: String?, handler: ((String?) -> Void)?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = text
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            handler?(alert.textFields?.first?.text)
        })
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
