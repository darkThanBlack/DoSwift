//
//  HierarchyCellModels.swift
//  DoSwift
//
//  Translated from DoraemonHierarchyTitleCell, DoraemonHierarchyDetailTitleCell,
//  DoraemonHierarchySwitchCell, DoraemonHierarchySelectorCell
//
//  Note: ObjC cells use AutoLayout. Swift version mirrors the layout in frame for
//  consistency with the rest of DoSwift's frame-based approach.
//

import UIKit

// MARK: - Title Cell

class HierarchyTitleCell: UITableViewCell {

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.black.withAlphaComponent(0.8)
        return label
    }()

    var model: HierarchyCellModel? {
        didSet { titleLabel.text = model?.title }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }

    func initUI() {
        selectedBackgroundView = UIView()
        selectionStyle = .none
        contentView.addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 10, y: 10, width: 120, height: contentView.bounds.height - 20)
    }
}

// MARK: - Detail Title Cell

class HierarchyDetailTitleCell: HierarchyTitleCell {

    private(set) lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.black.withAlphaComponent(0.8)
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    override func initUI() {
        super.initUI()
        contentView.addSubview(detailLabel)
    }

    override var model: HierarchyCellModel? {
        didSet {
            super.model = model
            if let detail = model?.detailTitle, !detail.isEmpty {
                detailLabel.text = detail
            } else {
                detailLabel.text = " "
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let titleRight = titleLabel.frame.maxX
        detailLabel.frame = CGRect(
            x: titleRight + 5,
            y: 10,
            width: contentView.bounds.width - titleRight - 20,
            height: contentView.bounds.height - 20
        )
    }
}

// MARK: - Selector Cell

class HierarchySelectorCell: HierarchyDetailTitleCell {
    override func initUI() {
        super.initUI()
        accessoryType = .disclosureIndicator
    }
}

// MARK: - Switch Cell

class HierarchySwitchCell: HierarchyDetailTitleCell {

    private lazy var swit: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        return s
    }()

    override func initUI() {
        super.initUI()
        contentView.addSubview(swit)
    }

    override var model: HierarchyCellModel? {
        didSet {
            super.model = model
            swit.isOn = model?.flag ?? false
        }
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        model?.flag = sender.isOn
        model?.changePropertyBlock?(sender.isOn)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let detailRight = detailLabel.frame.maxX
        swit.sizeToFit()
        swit.frame = CGRect(
            x: detailRight + 5,
            y: (contentView.bounds.height - swit.bounds.height) / 2,
            width: swit.bounds.width,
            height: swit.bounds.height
        )
    }
}
