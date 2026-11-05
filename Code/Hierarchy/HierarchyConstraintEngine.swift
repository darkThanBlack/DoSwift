//
//  HierarchyConstraintEngine.swift
//  DoSwift
//
//  Created by moonShadow on 2026/11/05
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    struct HierarchyConstraintEntry {
        let constraint: NSLayoutConstraint
        let owner: UIView
    }

    /// The equation split into pieces. The list shows `fullText`; the editor card shows
    /// `skeleton` because the values it appends already have input fields.
    struct HierarchyConstraintSummary {
        let left: String
        let relation: String
        let right: String?
        let multiplier: String?
        let constant: String?
        let priority: String?
        let isActive: Bool
        let identifier: String?

        var skeleton: String {
            var parts = [left, relation]
            if let right = right { parts.append(right) }
            if let multiplier = multiplier { parts.append(multiplier) }
            return parts.joined(separator: " ")
        }

        var fullText: String {
            var parts = [skeleton]
            if let constant = constant { parts.append(constant) }
            if let priority = priority { parts.append(priority) }
            if !isActive { parts.append(DO.Text.Hierarchy.constraintInactive) }
            return parts.joined(separator: " ")
        }
    }

    final class HierarchyConstraintEngine {

        static let shared = DO.HierarchyConstraintEngine()

        private struct Original {
            let constraint: NSLayoutConstraint
            let constant: CGFloat
            let priority: UILayoutPriority
            let isActive: Bool
        }

        private var originals: [ObjectIdentifier: Original] = [:]
        private var order: [ObjectIdentifier] = []

        private init() {}

        // MARK: - Collection

        /// Constraints involving `view`, walking the selected view and its ancestors. Only
        /// constraints that are actually installed in a `constraints` array show up, which
        /// keeps the synthesized content-size / autoresizing ones out.
        func entries(involving view: UIView) -> [DO.HierarchyConstraintEntry] {
            var seen = Set<ObjectIdentifier>()
            var result: [DO.HierarchyConstraintEntry] = []

            let arrangedStack = (view.superview as? UIStackView).flatMap { stack in
                return stack.arrangedSubviews.contains(view) ? stack : nil
            }

            var node: UIView? = view
            while let owner = node {
                for constraint in owner.constraints {
                    // Stack internals are not user constraints; the stack's own properties are
                    // the editable surface for an arranged subview.
                    if let arrangedStack = arrangedStack, owner === arrangedStack { continue }
                    guard involves(constraint, view) else { continue }
                    guard seen.insert(ObjectIdentifier(constraint)).inserted else { continue }
                    result.append(DO.HierarchyConstraintEntry(constraint: constraint, owner: owner))
                }
                node = owner.superview
            }
            return result
        }

        private func involves(_ constraint: NSLayoutConstraint, _ view: UIView) -> Bool {
            if (constraint.firstItem as? UIView) === view { return true }
            if (constraint.secondItem as? UIView) === view { return true }
            return false
        }

        // MARK: - Display

        func summary(for constraint: NSLayoutConstraint, from view: UIView) -> DO.HierarchyConstraintSummary {
            let left = "\(name(of: constraint.firstItem)).\(Self.name(of: constraint.firstAttribute))"

            var right: String?
            if let item = constraint.secondItem {
                right = "\(name(of: item)).\(Self.name(of: constraint.secondAttribute))"
            }

            var multiplier: String?
            if abs(constraint.multiplier - 1) > .ulpOfOne {
                multiplier = "× \(format(constraint.multiplier))"
            }

            var constant: String?
            if constraint.constant != 0 {
                let number = format(abs(constraint.constant))
                // Without a second item the constant is the right-hand side itself.
                constant = constraint.secondItem == nil
                    ? number
                    : (constraint.constant > 0 ? "+ \(number)" : "- \(number)")
            }

            let priority: String? = constraint.priority.rawValue != UILayoutPriority.required.rawValue
                ? "@\(Int(constraint.priority.rawValue))"
                : nil

            return DO.HierarchyConstraintSummary(
                left: left,
                relation: Self.relationName(constraint.relation),
                right: right,
                multiplier: multiplier,
                constant: constant,
                priority: priority,
                isActive: constraint.isActive,
                identifier: constraint.identifier
            )
        }

        private func name(of item: AnyObject?) -> String {
            if let item = item as? UIView {
                return String(describing: type(of: item))
            }
            if let guide = item as? UILayoutGuide {
                return guide.identifier.isEmpty ? "guide" : guide.identifier
            }
            return item.map { String(describing: type(of: $0)) } ?? "?"
        }

        private static func name(of attribute: NSLayoutConstraint.Attribute) -> String {
            switch attribute {
            case .left:            return "left"
            case .right:           return "right"
            case .top:             return "top"
            case .bottom:          return "bottom"
            case .leading:         return "leading"
            case .trailing:        return "trailing"
            case .width:           return "width"
            case .height:          return "height"
            case .centerX:         return "centerX"
            case .centerY:         return "centerY"
            case .lastBaseline:    return "lastBaseline"
            case .firstBaseline:   return "firstBaseline"
            case .leftMargin:      return "leftMargin"
            case .rightMargin:     return "rightMargin"
            case .topMargin:       return "topMargin"
            case .bottomMargin:    return "bottomMargin"
            case .leadingMargin:   return "leadingMargin"
            case .trailingMargin:  return "trailingMargin"
            case .centerXWithinMargins: return "centerXWithinMargins"
            case .centerYWithinMargins: return "centerYWithinMargins"
            case .notAnAttribute:  return "?"
            @unknown default:      return "attribute(\(attribute.rawValue))"
            }
        }

        private static func relationName(_ relation: NSLayoutConstraint.Relation) -> String {
            switch relation {
            case .equal:              return "=="
            case .greaterThanOrEqual: return ">="
            case .lessThanOrEqual:    return "<="
            @unknown default:         return "?"
            }
        }

        private func format(_ value: CGFloat) -> String {
            return DO.HierarchyFormatterTool.format(NSNumber(value: Double(value)))
        }

        // MARK: - Editing

        var editedCount: Int { originals.count }

        func setConstant(_ constant: CGFloat, on constraint: NSLayoutConstraint, in view: UIView) {
            record(constraint)
            constraint.constant = constant
            DO.HierarchyLayoutRefresh.refresh(view)
        }

        func setPriority(_ priority: UILayoutPriority, on constraint: NSLayoutConstraint, in view: UIView) {
            record(constraint)
            constraint.priority = priority
            DO.HierarchyLayoutRefresh.refresh(view)
        }

        func setActive(_ isActive: Bool, on constraint: NSLayoutConstraint, in view: UIView) {
            record(constraint)
            constraint.isActive = isActive
            DO.HierarchyLayoutRefresh.refresh(view)
        }

        /// Puts every edited constraint back the way it was found.
        func revertAll(in view: UIView) {
            for key in order {
                guard let original = originals[key] else { continue }
                original.constraint.constant = original.constant
                original.constraint.priority = original.priority
                original.constraint.isActive = original.isActive
            }
            originals.removeAll()
            order.removeAll()
            DO.HierarchyLayoutRefresh.refresh(view)
        }

        private func record(_ constraint: NSLayoutConstraint) {
            let key = ObjectIdentifier(constraint)
            guard originals[key] == nil else { return }
            originals[key] = Original(constraint: constraint,
                                      constant: constraint.constant,
                                      priority: constraint.priority,
                                      isActive: constraint.isActive)
            order.append(key)
        }
    }
}
