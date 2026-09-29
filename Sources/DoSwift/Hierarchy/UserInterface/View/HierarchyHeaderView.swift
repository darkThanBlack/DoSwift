//
//  HierarchyHeaderView.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyHeaderView.m / DoraemonHierarchyHeaderView.h
//

import UIKit

class HierarchyHeaderView: UIView {

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .black
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }

    private func initUI() {
        addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 10, y: 0, width: bounds.width - 20, height: bounds.height)
    }
}
