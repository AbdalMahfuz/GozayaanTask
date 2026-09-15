import UIKit

/// Spec 05 §3.3, 02 §2.1. Loading-only, first item: fake progress bar plus
/// the "Hang tight!" title.
final class LoadingBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadingBannerCell"

    private let progressBarView = ProgressBarView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressBarView.reset()
    }

    private func setUp() {
        isAccessibilityElement = true
        accessibilityLabel = "Loading flights"
        accessibilityTraits = .updatesFrequently

        titleLabel.text = "Hang tight! We\u{2019}re finding the best flight options for you."
        titleLabel.font = Theme.Typography.loadingTitle
        titleLabel.textColor = Theme.Colors.onNavy
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 3

        [progressBarView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            progressBarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            progressBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressBarView.heightAnchor.constraint(equalToConstant: 8),

            titleLabel.topAnchor.constraint(equalTo: progressBarView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36)
        ])
    }
}
