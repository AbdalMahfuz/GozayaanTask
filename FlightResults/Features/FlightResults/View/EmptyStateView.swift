import UIKit

/// Spec 05 §3.5, 02 §2.3. Set as the collection view's `backgroundView` in
/// `.empty`. No button (D-26).
final class EmptyStateView: UIView {
    // Invisible; only its height (a fraction of `self`'s) pushes the icon
    // down to "25% of the collection's height" (05 §3.5). Auto Layout can't
    // relate a position attribute (`.top`) to a size attribute (`.height`)
    // directly — height-to-height, between two different views, is the
    // valid form of that trick.
    private let topSpacerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: EmptyStateViewData) {
        titleLabel.text = data.title
        messageLabel.text = data.message
    }

    private func setUp() {
        iconImageView.image = UIImage(systemName: "airplane.departure")?
            .applyingSymbolConfiguration(.init(pointSize: 48))
        iconImageView.tintColor = Theme.Colors.brandBlue
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = Theme.Typography.stateTitle
        titleLabel.textColor = Theme.Colors.onNavy
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = Theme.Typography.stateMessage
        messageLabel.textColor = Theme.Colors.onNavySecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        [topSpacerView, iconImageView, titleLabel, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            topSpacerView.topAnchor.constraint(equalTo: topAnchor),
            topSpacerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSpacerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.25),

            iconImageView.topAnchor.constraint(equalTo: topSpacerView.bottomAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -32)
        ])
    }
}
