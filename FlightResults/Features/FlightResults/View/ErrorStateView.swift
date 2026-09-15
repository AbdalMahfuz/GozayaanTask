import UIKit

/// Spec 05 §3.5, 02 §2.4. Set as the collection view's `backgroundView` in
/// `.error`. `onRetry` is forwarded to `viewModel.retry()` by the VC — this
/// view only knows about the button tap, not the ViewModel.
final class ErrorStateView: UIView {
    // See `EmptyStateView.topSpacerView` — same "25% of height" positioning
    // trick, done via a height-to-height constraint instead of the invalid
    // top-to-height pairing.
    private let topSpacerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let tryAgainButton = UIButton(type: .system)
    private let debugDetailLabel = UILabel()

    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: ErrorStateViewData) {
        let symbolName = data.kind == .connectivity ? "wifi.slash" : "exclamationmark.triangle"
        iconImageView.image = UIImage(systemName: symbolName)?.applyingSymbolConfiguration(.init(pointSize: 48))
        titleLabel.text = data.title
        messageLabel.text = data.message

        #if DEBUG
        debugDetailLabel.text = data.debugDetail
        debugDetailLabel.isHidden = data.debugDetail == nil
        #else
        debugDetailLabel.isHidden = true
        #endif
    }

    private func setUp() {
        iconImageView.tintColor = Theme.Colors.yellow
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = Theme.Typography.stateTitle
        titleLabel.textColor = Theme.Colors.onNavy
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = Theme.Typography.stateMessage
        messageLabel.textColor = Theme.Colors.onNavySecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Try Again"
        buttonConfig.baseBackgroundColor = Theme.Colors.yellow
        buttonConfig.baseForegroundColor = Theme.Colors.textPrimary
        buttonConfig.cornerStyle = .fixed
        buttonConfig.background.cornerRadius = 8
        buttonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Typography.button
            return outgoing
        }
        tryAgainButton.configuration = buttonConfig
        tryAgainButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        debugDetailLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        debugDetailLabel.textColor = Theme.Colors.onNavy.withAlphaComponent(0.5)
        debugDetailLabel.textAlignment = .center
        debugDetailLabel.numberOfLines = 0
        debugDetailLabel.isHidden = true

        [topSpacerView, iconImageView, titleLabel, messageLabel, tryAgainButton, debugDetailLabel].forEach {
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

            tryAgainButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            tryAgainButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            tryAgainButton.widthAnchor.constraint(equalToConstant: 200),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 44),

            debugDetailLabel.topAnchor.constraint(equalTo: tryAgainButton.bottomAnchor, constant: 12),
            debugDetailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            debugDetailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            debugDetailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
