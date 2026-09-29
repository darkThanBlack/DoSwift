//
//  HierarchyCellModel.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyCellModel.m / .h
//

import UIKit

/// TableView Cell 数据模型
class HierarchyCellModel {

    let title: String?
    let detailTitle: String?

    /// Switch cell: flag
    var flag: Bool = false

    /// Stepper value
    var value: CGFloat = 0
    let minValue: CGFloat
    let maxValue: CGFloat

    /// Cell reuse class identifier
    private(set) var cellClass: String

    /// Selection action
    var block: (() -> Void)?

    /// Property change callback
    var changePropertyBlock: ((Any?) -> Void)?

    /// Separator insets
    var separatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

    // MARK: - Switch cell init
    init(title: String?, flag: Bool) {
        self.title = title
        self.detailTitle = nil
        self.flag = flag
        self.minValue = 0
        self.maxValue = 0
        self.cellClass = "HierarchySwitchCell"
    }

    init(title: String?, detailTitle: String?, flag: Bool) {
        self.title = title
        self.detailTitle = detailTitle
        self.flag = flag
        self.minValue = 0
        self.maxValue = 0
        self.cellClass = "HierarchySwitchCell"
    }

    // MARK: - Detail cell init
    init(title: String?, detailTitle: String?) {
        self.title = title
        self.detailTitle = detailTitle
        self.minValue = 0
        self.maxValue = 0
        self.cellClass = "HierarchyDetailTitleCell"
    }

    // TODO: Stepper cell init - not yet translated

    @discardableResult
    func normalInsets() -> HierarchyCellModel {
        separatorInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        return self
    }

    @discardableResult
    func noneInsets() -> HierarchyCellModel {
        separatorInsets = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        return self
    }

    func setBlock(_ block: @escaping () -> Void) {
        self.block = block
        cellClass = "HierarchySelectorCell"
    }
}
