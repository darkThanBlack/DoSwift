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
        table.register(DoSwiftMenuCell.self, forCellReuseIdentifier: DoSwiftMenuCell.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false

        // 添加背景点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)

        return view
    }()

    private lazy var menuContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear
        navigationController?.isNavigationBarHidden = true

        view.addSubview(backgroundView)
        view.addSubview(menuContainerView)
        menuContainerView.addSubview(tableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Menu Container
            menuContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            menuContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            menuContainerView.widthAnchor.constraint(equalToConstant: 220),
            menuContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),

            // Table View
            tableView.topAnchor.constraint(equalTo: menuContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: menuContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: menuContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: menuContainerView.bottomAnchor)
        ])

        // 动态计算菜单高度
        let itemCount = menuItems.count
        let maxVisibleItems = 7
        let visibleItems = min(itemCount, maxVisibleItems)
        let menuHeight = CGFloat(visibleItems * 54)

        menuContainerView.heightAnchor.constraint(equalToConstant: menuHeight).isActive = true
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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
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
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),

            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 12)
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