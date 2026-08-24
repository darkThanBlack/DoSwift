//
//  HierarchyInfoView.swift
//  DoSwift
//
//  Translated from DKHierarchyInfoView.m / DKHierarchyInfoView.h
//

import UIKit

protocol HierarchyInfoViewDelegate: AnyObject {
    func hierarchyInfoView(_ view: HierarchyInfoView, didSelect action: HierarchyInfoViewAction)
    func hierarchyInfoViewDidSelectClose(_ view: HierarchyInfoView)
}

enum HierarchyInfoViewAction: Int {
    case showParent = 0
    case showSubview = 1
    case showMoreInfo = 2
}

/// 属性信息浮窗
class HierarchyInfoView: MoveView {

    weak var delegate: HierarchyInfoViewDelegate?

    private(set) var selectedView: UIView?

    // MARK: - Subviews

    private(set) lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        // TODO: Use actual close asset - doraemon_close
        btn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        btn.tintColor = .darkGray
        return btn
    }()

    private lazy var contentLabel: UILabel = makeLabel()
    private lazy var frameLabel: UILabel = makeLabel(tappable: #selector(frameTapped))
    private lazy var backgroundColorLabel: UILabel = makeLabel(tappable: #selector(backgroundColorTapped))
    private lazy var textColorLabel: UILabel = makeLabel(tappable: #selector(textColorTapped))
    private lazy var fontLabel: UILabel = makeLabel(tappable: #selector(fontTapped))
    private lazy var tagLabel: UILabel = makeLabel(tappable: #selector(tagTapped))

    private lazy var actionContentView: UIView = UIView()

    private lazy var parentViewsButton: UIButton = makeActionButton(
        title: "Parent Views",
        // TODO: Use actual asset - doraemon_hierarchy_parent
        icon: UIImage(systemName: "arrow.up"),
        tag: .showParent
    )

    private lazy var subviewsButton: UIButton = makeActionButton(
        title: "Subviews",
        // TODO: Use actual asset - doraemon_hierarchy_subview
        icon: UIImage(systemName: "arrow.down"),
        tag: .showSubview
    )

    private lazy var moreButton: UIButton = makeActionButton(
        title: "More Info",
        // TODO: Use actual asset - doraemon_hierarchy_info
        icon: UIImage(systemName: "info.circle"),
        tag: .showMoreInfo
    )

    private var actionContentHeight: CGFloat = 80

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        hierarchyInfoViewInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hierarchyInfoViewInit()
    }

    private func hierarchyInfoViewInit() {
        layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 5
        layer.masksToBounds = true
        backgroundColor = .white

        addSubview(closeButton)
        addSubview(contentLabel)
        addSubview(frameLabel)
        addSubview(backgroundColorLabel)
        addSubview(textColorLabel)
        addSubview(fontLabel)
        addSubview(tagLabel)
        addSubview(actionContentView)

        actionContentView.addSubview(parentViewsButton)
        actionContentView.addSubview(subviewsButton)
        actionContentView.addSubview(moreButton)

        updateHeightIfNeeded()
    }

    // MARK: - Update

    func updateSelectedView(_ view: UIView?) {
        guard let view = view, view !== selectedView else { return }

        moreButton.isEnabled = true
        parentViewsButton.isEnabled = view.superview != nil
        subviewsButton.isEnabled = !view.subviews.isEmpty

        selectedView = view

        let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 17)]
        let normal: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]

        // Name
        let name = NSMutableAttributedString(string: "Name: ", attributes: bold)
        name.append(NSAttributedString(string: String(describing: type(of: view)), attributes: normal))
        contentLabel.attributedText = name

        // Frame
        let frame = NSMutableAttributedString(string: "Frame: ", attributes: bold)
        frame.append(NSAttributedString(string: HierarchyFormatterTool.string(from: view.frame), attributes: normal))
        frameLabel.attributedText = frame

        // Background
        if let bg = view.backgroundColor {
            let color = NSMutableAttributedString(string: "Background: ", attributes: bold)
            color.append(NSAttributedString(string: bg.hierarchy_description, attributes: normal))
            backgroundColorLabel.attributedText = color
        } else {
            backgroundColorLabel.attributedText = nil
        }

        // Text Color / Font (UILabel specific)
        if let label = view as? UILabel {
            let tc = NSMutableAttributedString(string: "Text Color: ", attributes: bold)
            tc.append(NSAttributedString(string: label.textColor.hierarchy_description, attributes: normal))
            textColorLabel.attributedText = tc

            let font = NSMutableAttributedString(string: "Font: ", attributes: bold)
            font.append(NSAttributedString(string: String(format: "%0.2f", label.font.pointSize), attributes: normal))
            fontLabel.attributedText = font
        } else {
            textColorLabel.attributedText = nil
            fontLabel.attributedText = nil
        }

        // Tag
        if view.tag != 0 {
            let tag = NSMutableAttributedString(string: "Tag: ", attributes: bold)
            tag.append(NSAttributedString(string: "\(view.tag)", attributes: normal))
            tagLabel.attributedText = tag
        } else {
            tagLabel.attributedText = nil
        }

        [contentLabel, frameLabel, backgroundColorLabel, textColorLabel, fontLabel, tagLabel].forEach { $0.sizeToFit() }
        updateHeightIfNeeded()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = bounds.width, h = bounds.height

        closeButton.frame = CGRect(x: w - 40, y: 10, width: 30, height: 30)

        actionContentView.frame = CGRect(x: 0, y: h - actionContentHeight - 10, width: w, height: actionContentHeight)

        let acw = actionContentView.bounds.width
        let ach = actionContentView.bounds.height
        let btnW = acw / 2 - 15
        let btnH = (ach - 10) / 2

        parentViewsButton.frame = CGRect(x: 10, y: 0, width: btnW, height: btnH)
        subviewsButton.frame = CGRect(x: acw / 2 + 5, y: 0, width: btnW, height: btnH)
        moreButton.frame = CGRect(x: 10, y: btnH + 10, width: acw - 20, height: btnH)

        let labelWidth = closeButton.frame.minX - 20
        var y: CGFloat = 10

        contentLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: contentLabel.bounds.height)
        y = contentLabel.frame.maxY

        frameLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: frameLabel.bounds.height)
        y = frameLabel.frame.maxY

        backgroundColorLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: backgroundColorLabel.bounds.height)
        y = backgroundColorLabel.frame.maxY

        textColorLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: textColorLabel.bounds.height)
        y = textColorLabel.frame.maxY

        fontLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: fontLabel.bounds.height)
        y = fontLabel.frame.maxY

        tagLabel.frame = CGRect(x: 10, y: y, width: labelWidth, height: tagLabel.bounds.height)
    }

    private func updateHeightIfNeeded() {
        let contentH = contentLabel.bounds.height + frameLabel.bounds.height
            + backgroundColorLabel.bounds.height + textColorLabel.bounds.height
            + fontLabel.bounds.height + tagLabel.bounds.height
        let newHeight: CGFloat = 10 + max(contentH, 40) + 10 + actionContentHeight + 10

        if newHeight != bounds.height {
            var f = frame
            f.size.height = newHeight
            frame = f

            if !isMoved {
                let screenH = UIScreen.main.bounds.height
                if f.maxY != screenH - 20 {
                    f.origin.y = screenH - 20 - newHeight
                    frame = f
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func buttonTapped(_ sender: UIButton) {
        guard let action = HierarchyInfoViewAction(rawValue: sender.tag) else { return }
        delegate?.hierarchyInfoView(self, didSelect: action)
    }

    @objc private func closeTapped() {
        delegate?.hierarchyInfoViewDidSelectClose(self)
    }

    // TODO: Property write-back (editing) is deferred to a later pass.
    @objc private func frameTapped() {}
    @objc private func backgroundColorTapped() {}
    @objc private func textColorTapped() {}
    @objc private func fontTapped() {}
    @objc private func tagTapped() {}

    // MARK: - Helpers

    private func makeLabel(tappable selector: Selector? = nil) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.black.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        if let sel = selector {
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: sel))
        }
        return label
    }

    private func makeActionButton(title: String, icon: UIImage?, tag: HierarchyInfoViewAction) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.backgroundColor = .white
        btn.layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        btn.tintColor = UIColor.black.withAlphaComponent(0.8)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        btn.setImage(icon?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tag = tag.rawValue
        btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }
}
