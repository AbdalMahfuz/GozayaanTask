import UIKit

/// Spec 05 §3.3, 02 §2.1. Loading-only, first item. The progress bar is a
/// fake, non-blocking indicator (SerpApi gives no real progress events): it
/// eases from 0 to 90 % over ~8 s and then just waits there.
final class LoadingBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadingBannerCell"

    private let trackView = UIView()
    private let fillView = UIView()
    private let titleLabel = UILabel()
    private var fillWidthConstraint: NSLayoutConstraint!
    private var hasStartedProgress = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        startProgressIfNeeded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        fillView.layer.removeAllAnimations()
        fillWidthConstraint.constant = 0
        hasStartedProgress = false
    }

    private func setUp() {
        isAccessibilityElement = true
        accessibilityLabel = "Loading flights"
        accessibilityTraits = .updatesFrequently

        trackView.backgroundColor = Theme.Colors.cardBackground
        trackView.layer.cornerRadius = 4
        trackView.clipsToBounds = true

        fillView.backgroundColor = Theme.Colors.progressOrange
        fillView.layer.cornerRadius = 4

        titleLabel.text = "Hang tight! We\u{2019}re finding the best flight options for you."
        titleLabel.font = Theme.Typography.loadingTitle
        titleLabel.textColor = Theme.Colors.onNavy
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 3

        [trackView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        fillView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(fillView)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            trackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            trackView.heightAnchor.constraint(equalToConstant: 8),

            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillWidthConstraint,

            titleLabel.topAnchor.constraint(equalTo: trackView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36)
        ])
    }

    private func startProgressIfNeeded() {
        guard !hasStartedProgress, trackView.bounds.width > 0 else { return }
        hasStartedProgress = true
        let targetWidth = trackView.bounds.width * 0.9
        fillWidthConstraint.constant = targetWidth

        if UIAccessibility.isReduceMotionEnabled {
            layoutIfNeeded()
        } else {
            UIView.animate(withDuration: 8, delay: 0, options: [.curveEaseOut]) {
                self.layoutIfNeeded()
            }
        }
    }
}
