//
//  HierarchyConstraintEditorCard.swift
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

    /// One constraint: the equation as a subtitle, then constant / priority / active.
    /// Only the three writable properties are exposed; the rest of a constraint is immutable.
    @objc(DOHierarchyConstraintEditorCard)
    final class HierarchyConstraintEditorCard: DO.BaseAlertViewController {

        private let constraint: NSLayoutConstraint
        private let summary: DO.HierarchyConstraintSummary
        private weak var targetView: UIView?
        private let onCommit: () -> Void

        private let originalConstant: CGFloat
        private let originalPriority: UILayoutPriority

        init(
            constraint: NSLayoutConstraint,
            summary: DO.HierarchyConstraintSummary,
            targetView: UIView,
            onCommit: @escaping () -> Void
        ) {
            self.constraint = constraint
            self.summary = summary
            self.targetView = targetView
            self.onCommit = onCommit

            self.originalConstant = constraint.constant
            self.originalPriority = constraint.priority

            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()

            maskTapEventHandler = { [weak self] in self?.dismiss(animated: true) }

            setupCard()
            validate()

            constantField.onValueChanged = { [weak self] in self?.validate() }
            priorityField.onValueChanged = { [weak self] in self?.validate() }
        }

        // MARK: - Card

        private lazy var cardView: UIView = {
            let view = UIView()
            view.backgroundColor = .systemBackground
            view.layer.cornerRadius = 16
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.18
            view.layer.shadowRadius = 22
            view.layer.shadowOffset = CGSize(width: 0, height: 8)
            return view
        }()

        private lazy var clipper: UIView = {
            let view = UIView()
            view.backgroundColor = .systemBackground
            view.layer.cornerRadius = 16
            view.layer.masksToBounds = true
            return view
        }()

        private lazy var doneButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle(DO.Text.Hierarchy.done, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.tertiaryLabel, for: .disabled)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 9
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.addTarget(self, action: #selector(commit), for: .touchUpInside)
            return button
        }()

        private lazy var constantField: DO.HierarchyNumberFieldView = {
            return DO.HierarchyNumberFieldView(isInteger: false, step: 1,
                                               value: Double(constraint.constant), prominent: false)
        }()

        private lazy var priorityField: DO.HierarchyNumberFieldView = {
            return DO.HierarchyNumberFieldView(isInteger: true, step: 50,
                                               value: Double(constraint.priority.rawValue), prominent: false)
        }()

        private func setupCard() {
            cardView.addSubview(clipper)
            contentView.addSubview(cardView)

            cardView.translatesAutoresizingMaskIntoConstraints = false
            clipper.translatesAutoresizingMaskIntoConstraints = false

            let cardWidth = DO.Core.screenBounds.width - 32
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
                cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

                cardView.widthAnchor.constraint(equalToConstant: cardWidth),
                cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                              constant: 16),
                cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                 constant: -16),

                clipper.topAnchor.constraint(equalTo: cardView.topAnchor),
                clipper.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
                clipper.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
                clipper.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            ])

            buildCardContents()
        }

        private func buildCardContents() {
            let titleLabel = UILabel()
            titleLabel.text = summary.identifier?.isEmpty == false
                ? summary.identifier
                : DO.Text.Hierarchy.constraintTitle
            titleLabel.font = .monospacedSystemFont(ofSize: 17, weight: .semibold)
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.7
            titleLabel.numberOfLines = 1

            let subtitleLabel = UILabel()
            subtitleLabel.text = summary.skeleton
            subtitleLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.numberOfLines = 2
            subtitleLabel.lineBreakMode = .byWordWrapping

            let grabber = UIView()
            grabber.backgroundColor = .tertiaryLabel
            grabber.layer.cornerRadius = 2.5

            let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            titleStack.axis = .vertical
            titleStack.alignment = .fill
            titleStack.spacing = 3

            let header = UIView()
            [grabber, titleStack].forEach(header.addSubview)
            header.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))

            let bodyStack = UIStackView(arrangedSubviews: [
                makeRow(DO.Text.Hierarchy.constraintConstant, constantField),
                makeRow(DO.Text.Hierarchy.constraintPriority, priorityField),
            ])
            bodyStack.axis = .vertical
            bodyStack.spacing = DO.HierarchyEditorStyle.rowGap
            bodyStack.isLayoutMarginsRelativeArrangement = true
            bodyStack.layoutMargins = UIEdgeInsets(top: 16, left: DO.HierarchyEditorStyle.padding,
                                                   bottom: 16, right: DO.HierarchyEditorStyle.padding)

            let bottomBar = UIView()
            bottomBar.addSubview(doneButton)

            let stack = UIStackView(arrangedSubviews: [header, divider(), bodyStack, divider(), bottomBar])
            stack.axis = .vertical
            stack.spacing = 0
            clipper.addSubview(stack)

            [stack, grabber, titleStack, titleLabel, subtitleLabel, header,
             bodyStack, bottomBar, doneButton].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: clipper.topAnchor),
                stack.leadingAnchor.constraint(equalTo: clipper.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: clipper.trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: clipper.bottomAnchor),

                grabber.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
                grabber.centerXAnchor.constraint(equalTo: header.centerXAnchor),
                grabber.widthAnchor.constraint(equalToConstant: 36),
                grabber.heightAnchor.constraint(equalToConstant: 5),

                titleStack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 12),
                titleStack.leadingAnchor.constraint(equalTo: header.leadingAnchor,
                                                    constant: DO.HierarchyEditorStyle.padding),
                titleStack.trailingAnchor.constraint(equalTo: header.trailingAnchor,
                                                     constant: -DO.HierarchyEditorStyle.padding),
                titleStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16),

                doneButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 10),
                doneButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -10),
                doneButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor,
                                                     constant: -DO.HierarchyEditorStyle.padding),
            ])
        }

        private func makeRow(_ title: String, _ control: UIView) -> UIStackView {
            let label = DO.HierarchyEditorStyle.makeLabel(title)
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.widthAnchor.constraint(equalToConstant: 72).isActive = true

            let row = UIStackView(arrangedSubviews: [label, control])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            return row
        }

        private func divider() -> UIView {
            let line = UIView()
            line.backgroundColor = .separator
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
            return line
        }

        // MARK: - Values

        private func currentConstant() -> CGFloat? {
            guard case let .double(value)? = constantField.readValue() else { return nil }
            return CGFloat(value)
        }

        private func currentPriority() -> UILayoutPriority? {
            guard case let .int(value)? = priorityField.readValue(),
                  value >= 1, value <= 1000 else { return nil }
            return UILayoutPriority(Float(value))
        }

        private func validate() {
            let isValid = currentConstant() != nil && currentPriority() != nil
            doneButton.isEnabled = isValid
            doneButton.backgroundColor = isValid ? .systemBlue : .tertiarySystemFill
            doneButton.setTitleColor(isValid ? .white : .tertiaryLabel, for: .normal)
        }

        @objc private func commit() {
            guard let constant = currentConstant(), let priority = currentPriority() else { return }

            let engine = DO.HierarchyConstraintEngine.shared
            if let targetView = targetView {
                if constant != originalConstant {
                    engine.setConstant(constant, on: constraint, in: targetView)
                }
                if priority != originalPriority {
                    engine.setPriority(priority, on: constraint, in: targetView)
                }
            }

            onCommit()
            dismiss(animated: true)
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let offset = max(0, gesture.translation(in: view).y)

            switch gesture.state {
            case .changed:
                cardView.transform = CGAffineTransform(translationX: 0, y: offset)

            case .ended, .cancelled:
                if offset > 90 || gesture.velocity(in: view).y > 600 {
                    view.endEditing(true)
                    dismiss(animated: true)
                } else {
                    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                        self.cardView.transform = .identity
                    }
                }

            default:
                break
            }
        }
    }
}
