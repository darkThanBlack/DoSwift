//
//  HierarchyFormatterTool.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyFormatterTool.m
//

import UIKit

class HierarchyFormatterTool {
    static let shared = HierarchyFormatterTool()

    private lazy var formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private lazy var numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()

    func string(from date: Date) -> String? {
        formatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        formatter.date(from: string)
    }

    func format(_ number: NSNumber) -> String {
        numberFormatter.string(from: number) ?? "\(number)"
    }

    static func string(from date: Date) -> String? {
        shared.string(from: date)
    }

    static func date(from string: String) -> Date? {
        shared.date(from: string)
    }

    static func format(_ number: NSNumber) -> String {
        shared.format(number)
    }

    static func string(from frame: CGRect) -> String {
        "{{\(format(NSNumber(value: frame.origin.x))), \(format(NSNumber(value: frame.origin.y)))}, {\(format(NSNumber(value: frame.size.width))), \(format(NSNumber(value: frame.size.height)))}}"
    }
}
