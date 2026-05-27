//
//  HierarchyCategoryModel.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyCategoryModel.m / .h
//

import UIKit

class HierarchyCategoryModel {
    let title: String?
    let items: [HierarchyCellModel]

    init(title: String?, items: [HierarchyCellModel]) {
        self.title = title
        self.items = items
    }
}
