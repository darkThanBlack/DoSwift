//
//  HierarchyValueInput.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    protocol HierarchyValueInput: UIView {

        var onValidityChange: ((Bool) -> Void)? { get set }

        func readValue() -> DO.ValueKind?
    }

    enum HierarchyValueInputFactory {

        static func make(for kind: DO.ValueKind) -> DO.HierarchyValueInput? {
            switch kind {
            case .text(let text):
                return DO.HierarchyMultilineTextView(text: text)

            case .int(let value):
                return DO.HierarchyNumberFieldView(isInteger: true, step: 1, value: Double(value))

            case .double(let value):
                return DO.HierarchyNumberFieldView(isInteger: false, step: 0.1, value: value)

            case .enumValue(let raw, let table, _):
                return DO.HierarchyEnumListView(table: table, currentRawValue: raw)

            case .font(let font):
                return DO.HierarchyFontInputView(font: font)

            case .color(let color):
                return DO.HierarchyColorPanelView(color: color)

            case .date(let date):
                return DO.HierarchyDateInputView(date: date)

            case .size(let size):
                return DO.HierarchyNumberGridView(labels: ["width", "height"],
                                               values: [Double(size.width), Double(size.height)]) {
                    .size(CGSize(width: $0[0], height: $0[1]))
                }

            case .point(let point):
                return DO.HierarchyNumberGridView(labels: ["x", "y"],
                                               values: [Double(point.x), Double(point.y)]) {
                    .point(CGPoint(x: $0[0], y: $0[1]))
                }

            case .frame(let frame):
                return DO.HierarchyNumberGridView(labels: ["x", "y", "width", "height"],
                                               values: [Double(frame.origin.x), Double(frame.origin.y),
                                                        Double(frame.size.width), Double(frame.size.height)]) {
                    .frame(CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]))
                }

            case .insets(let insets):
                return DO.HierarchyNumberGridView(labels: ["top", "left", "bottom", "right"],
                                               values: [Double(insets.top), Double(insets.left),
                                                        Double(insets.bottom), Double(insets.right)]) {
                    .insets(UIEdgeInsets(top: $0[0], left: $0[1], bottom: $0[2], right: $0[3]))
                }

            case .bool, .image, .attributedText, .unknown:
                return nil
            }
        }
    }

    enum HierarchyEditorStyle {

        static let padding: CGFloat = 20
        static let rowGap: CGFloat = 14

        static let fieldBackground = UIColor.secondarySystemFill
        static let fieldRadius: CGFloat = 10

        static let labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let bodyFont = UIFont.systemFont(ofSize: 17)
        static let valueFont = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        static let prominentValueFont = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: .semibold)

        static func makeLabel(_ text: String) -> UILabel {
            let label = UILabel()
            label.text = text
            label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            return label
        }

        static func disableSmartInput(_ field: UITextField) {
            field.autocapitalizationType = .none
            field.autocorrectionType = .no
            field.spellCheckingType = .no
            field.smartQuotesType = .no
            field.smartDashesType = .no
            field.smartInsertDeleteType = .no
            field.textContentType = nil
        }

        static func disableSmartInput(_ view: UITextView) {
            view.autocapitalizationType = .none
            view.autocorrectionType = .no
            view.spellCheckingType = .no
            view.smartQuotesType = .no
            view.smartDashesType = .no
            view.smartInsertDeleteType = .no
            view.textContentType = nil
        }
    }
}
