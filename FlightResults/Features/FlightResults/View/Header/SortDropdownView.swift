import UIKit

extension SortOption {
    var displayTitle: String {
        switch self {
        case .cheapest: "Cheapest"
        case .fastest: "Fastest"
        }
    }
}

/// Spec 05 §2.4. A full-screen overlay (transparent backdrop that dismisses
/// on outside tap) holding a small panel anchored under the sort button.
/// Owns its own present/dismiss animation so the VC doesn't need to know
/// the timing details.
final class SortDropdownView: UIView {
    private let backdropButton = UIButton(type: .custom)
    private let panelView = UIView()
    private let stackView = UIStackView()
    private var rowButtons: [SortOption: UIButton] = [:]

    var onSelect: ((SortOption) -> Void)?
    var onDismissTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(selected: SortOption) {
        for (option, button) in rowButtons {
            let isSelected = option == selected
            button.backgroundColor = isSelected ? Theme.Colors.selectionTint : .clear
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }

    /// Adds `self` as a full-screen overlay in `container` and animates the
    /// panel in, anchored `leading` 16 pt from `container` and 8 pt below
    /// `anchorBottom` (the sort button's bottom edge).
    func show(
        in container: UIView,
        anchorLeading: NSLayoutXAxisAnchor,
        anchorBottom: NSLayoutYAxisAnchor
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor),
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),

            panelView.leadingAnchor.constraint(equalTo: anchorLeading, constant: 16),
            panelView.topAnchor.constraint(equalTo: anchorBottom, constant: 8)
        ])

        alpha = 0
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        panelView.transform = reduceMotion ? .identity : CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
            self.panelView.transform = .identity
        }
        UIAccessibility.post(notification: .screenChanged, argument: panelView)
    }

    func hide(completion: (() -> Void)? = nil) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
            if !reduceMotion {
                self.panelView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    private func setUp() {
        backgroundColor = .clear

        backdropButton.addTarget(self, action: #selector(backdropTapped), for: .touchUpInside)
        backdropButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdropButton)

        panelView.backgroundColor = Theme.Colors.cardBackground
        panelView.layer.cornerRadius = Theme.Spacing.dropdownRadius
        panelView.layer.shadowColor = UIColor.black.cgColor
        panelView.layer.shadowOpacity = 0.12
        panelView.layer.shadowOffset = CGSize(width: 0, height: 4)
        panelView.layer.shadowRadius = 16
        panelView.accessibilityViewIsModal = true
        panelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panelView)

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(stackView)

        for option in SortOption.allCases {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.title = option.displayTitle
            config.baseForegroundColor = Theme.Colors.navy
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            config.titleAlignment = .leading
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                return outgoing
            }
            button.configuration = config
            button.contentHorizontalAlignment = .leading
            button.layer.cornerRadius = 6
            button.accessibilityTraits = .button
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.rowTapped(option) }, for: .touchUpInside)
            rowButtons[option] = button
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            backdropButton.topAnchor.constraint(equalTo: topAnchor),
            backdropButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdropButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdropButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            panelView.widthAnchor.constraint(equalToConstant: 200),

            stackView.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -16)
        ])
    }

    private func rowTapped(_ option: SortOption) {
        onSelect?(option)
    }

    @objc private func backdropTapped() {
        onDismissTapped?()
    }
}
