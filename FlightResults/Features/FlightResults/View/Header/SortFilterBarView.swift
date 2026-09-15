import UIKit

/// Spec 05 §2.3. The button bar; `SortDropdownView` is a separate overlay
/// the VC presents on tap. Filter is decorative (no target).
final class SortFilterBarView: UIView {
    let sortButton = UIButton(type: .system)
    private let filterButton = UIButton(type: .system)

    var onSortTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(sortTitle: String, isEnabled: Bool) {
        var config = sortButton.configuration
        config?.title = sortTitle
        sortButton.configuration = config
        sortButton.isEnabled = isEnabled
        sortButton.alpha = isEnabled ? 1 : 0.5
    }

    /// Rotates the chevron to face up while the dropdown is open (spec 05
    /// §2.3: `chevron.down` → visually `chevron.up`, 0.2 s).
    func setDropdownExpanded(_ expanded: Bool) {
        let transform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        let duration = UIAccessibility.isReduceMotionEnabled ? 0 : 0.2
        UIView.animate(withDuration: duration) {
            self.sortButton.imageView?.transform = transform
        }
    }

    private func setUp() {
        let fontTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Typography.button
            return outgoing
        }

        var sortConfig = UIButton.Configuration.plain()
        sortConfig.title = "Cheapest"
        sortConfig.image = UIImage(systemName: "chevron.down")
        sortConfig.imagePlacement = .trailing
        sortConfig.imagePadding = 8
        sortConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        sortConfig.baseForegroundColor = Theme.Colors.onNavy
        sortConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        // Stay white when disabled: the spec's disabled look is the whole
        // button at 50 % alpha, not UIKit's grey disabled tint on top of it.
        sortConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Typography.button
            outgoing.foregroundColor = Theme.Colors.onNavy
            return outgoing
        }
        sortConfig.imageColorTransformer = UIConfigurationColorTransformer { _ in Theme.Colors.onNavy }
        // Border and radius go on the configuration's background: iOS 26
        // draws configuration buttons as capsules and ignores `layer.cornerRadius`.
        sortConfig.cornerStyle = .fixed
        sortConfig.background.cornerRadius = Theme.Spacing.buttonRadius
        sortConfig.background.strokeColor = Theme.Colors.sortBorder
        sortConfig.background.strokeWidth = 1
        sortButton.configuration = sortConfig
        sortButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)

        var filterConfig = UIButton.Configuration.filled()
        filterConfig.title = "Filter"
        filterConfig.image = UIImage(systemName: "slider.horizontal.3")
        filterConfig.imagePlacement = .trailing
        filterConfig.imagePadding = 8
        filterConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14)
        filterConfig.baseForegroundColor = Theme.Colors.textPrimary
        filterConfig.baseBackgroundColor = Theme.Colors.yellow
        filterConfig.titleTextAttributesTransformer = fontTransformer
        filterConfig.cornerStyle = .fixed
        filterConfig.background.cornerRadius = Theme.Spacing.buttonRadius
        filterButton.configuration = filterConfig
        filterButton.accessibilityLabel = "Filter"
        // Decorative: no target added.

        [sortButton, filterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            sortButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            sortButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            sortButton.heightAnchor.constraint(equalToConstant: 32),

            filterButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            filterButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 100),
            filterButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func sortTapped() {
        onSortTapped?()
    }
}
