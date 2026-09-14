import UIKit

/// Spec 05 §2.3. The dropdown itself is added in plan step 14 — this is the
/// button only. Filter is decorative (no target).
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
        sortConfig.titleTextAttributesTransformer = fontTransformer
        sortButton.configuration = sortConfig
        sortButton.layer.borderWidth = 1
        sortButton.layer.borderColor = Theme.Colors.sortBorder.cgColor
        sortButton.layer.cornerRadius = Theme.Spacing.buttonRadius
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
        filterButton.configuration = filterConfig
        filterButton.layer.cornerRadius = Theme.Spacing.buttonRadius
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
