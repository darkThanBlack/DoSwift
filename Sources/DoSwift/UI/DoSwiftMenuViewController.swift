//
//  DoSwiftMenuViewController.swift
//  DoSwift
//
//  Created by Claude Code on 2025/09/26.
//  Copyright © 2025 DoSwift. All rights reserved.
//

import UIKit

// MARK: - Delegate Protocol

protocol DoSwiftMenuViewControllerDelegate: AnyObject {
    func menuViewController(_ controller: DoSwiftMenuViewController, didSelectMenuItem menuItem: DoSwiftMenuItem)
    func menuViewControllerDidRequestClose(_ controller: DoSwiftMenuViewController)
}

// MARK: - DoSwiftMenuViewController

/// DoSwift 菜单视图控制器
class DoSwiftMenuViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: DoSwiftMenuViewControllerDelegate?

    /// 菜单项数据
    var menuItems: [DoSwiftMenuItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - UI Elements

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.systemBackground
        table.separatorStyle = .singleLine
        table.rowHeight = 54
        table.layer.masksToBounds = true
        table.register(DoSwiftMenuCell.self, forCellReuseIdentifier: DoSwiftMenuCell.identifier)
        return table
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear  // 移除灰色背景
        view.translatesAutoresizingMaskIntoConstraints = false

        // 添加背景点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)

        return view
    }()

    private lazy var menuContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.masksToBounds = false

        // 添加阴影效果替代灰色背景
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.25

        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadViews(in: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 动态设置圆角
        tableView.layer.cornerRadius = 12
        menuContainerView.layer.cornerRadius = 12
    }

    // MARK: - Setup

    private func loadViews(in box: UIView) {
        box.backgroundColor = .clear
        navigationController?.isNavigationBarHidden = true

        [backgroundView, menuContainerView].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        [tableView].forEach({
            menuContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        // Background constraints
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: box.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        ])

        // Menu Container constraints
        NSLayoutConstraint.activate([
            menuContainerView.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            menuContainerView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            menuContainerView.widthAnchor.constraint(equalToConstant: 220),
        ])

        // Table View constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: menuContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: menuContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: menuContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: menuContainerView.bottomAnchor),
        ])

        // 动态计算菜单高度
        let itemCount = menuItems.count
        let maxVisibleItems = 7
        let visibleItems = min(itemCount, maxVisibleItems)
        let menuHeight = CGFloat(visibleItems * 54)

        NSLayoutConstraint.activate([
            menuContainerView.heightAnchor.constraint(equalToConstant: menuHeight),
        ])
    }

    // MARK: - Actions

    @objc private func backgroundTapped() {
        animateOut {
            self.delegate?.menuViewControllerDidRequestClose(self)
        }
    }

    // MARK: - Animations

    private func animateIn() {
        menuContainerView.alpha = 0
        menuContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                self.menuContainerView.alpha = 1.0
                self.menuContainerView.transform = .identity
            }
        )
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                self.menuContainerView.alpha = 0
                self.menuContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            },
            completion: { _ in
                completion()
            }
        )
    }
}

// MARK: - UITableViewDataSource

extension DoSwiftMenuViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DoSwiftMenuCell.identifier, for: indexPath) as! DoSwiftMenuCell
        let menuItem = menuItems[indexPath.row]
        cell.configure(with: menuItem)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension DoSwiftMenuViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let menuItem = menuItems[indexPath.row]

        animateOut {
            self.delegate?.menuViewController(self, didSelectMenuItem: menuItem)
        }
    }
}

// MARK: - DoSwiftMenuCell

private class DoSwiftMenuCell: UITableViewCell {

    static let identifier = "DoSwiftMenuCell"

    // MARK: - UI Elements

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        return imageView
    }()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        loadViews(in: contentView)
    }

    private func loadViews(in box: UIView) {
        [iconImageView, titleLabel, arrowImageView].forEach({
            box.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
        ])

        NSLayoutConstraint.activate([
            arrowImageView.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    // MARK: - Configuration

    func configure(with menuItem: DoSwiftMenuItem) {
        titleLabel.text = menuItem.title
        iconImageView.image = menuItem.icon
        iconImageView.isHidden = (menuItem.icon == nil)
        arrowImageView.isHidden = !menuItem.hasSubMenu

        // 处理分隔符样式
        if menuItem.identifier.hasPrefix("separator") {
            backgroundColor = UIColor.systemGray6
            titleLabel.text = ""
            iconImageView.isHidden = true
            arrowImageView.isHidden = true
            isUserInteractionEnabled = false
        } else {
            backgroundColor = UIColor.systemBackground
            isUserInteractionEnabled = menuItem.isEnabled
            alpha = menuItem.isEnabled ? 1.0 : 0.5
        }
    }
}