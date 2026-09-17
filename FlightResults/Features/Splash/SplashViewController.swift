import UIKit

/// Animated splash shown before the results screen (D-36). iOS launch screens
/// are static, so the launch screen paints the same navy background and
/// `app_logo` at the screen's centre, and this controller starts from that
/// exact frame — the hand-off is invisible.
///
/// No ViewModel: there is no state or data here, only a timed animation, so
/// the Coordinator drives it through `onFinished`.
final class SplashViewController: UIViewController {
    private let logoImageView = UIImageView(image: UIImage(named: "app_logo"))
    private let titleStackView = UIStackView()
    private let subtitleLabel = UILabel()
    /// Starts at 0 to match the launch screen's centred logo; the intro moves
    /// the logo up to make room for the wordmark.
    private var logoCenterYConstraint: NSLayoutConstraint?

    /// Called once the intro finishes, so the Coordinator can swap in the
    /// results screen.
    var onFinished: (() -> Void)?

    private var hasAnimated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.navy
        setUpLayout()

        // One element for VoiceOver: the individual letters are decorative.
        view.isAccessibilityElement = true
        view.accessibilityLabel = "GoZayaan Flights"
        view.accessibilityTraits = .staticText
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimated else { return }
        hasAnimated = true
        runIntro()
    }

    private func setUpLayout() {
        // Corners are baked into `app_logo` (the launch screen can't round
        // them), so no layer clipping here; that keeps both frames identical.
        logoImageView.contentMode = .scaleAspectFit

        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 0
        for character in "GoZayaan" {
            let label = UILabel()
            label.text = String(character)
            label.font = Theme.Typography.splashTitle
            label.textColor = Theme.Colors.onNavy
            label.alpha = 0
            titleStackView.addArrangedSubview(label)
        }

        subtitleLabel.text = "Find your flight"
        subtitleLabel.font = Theme.Typography.splashSubtitle
        subtitleLabel.textColor = Theme.Colors.yellow
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0

        [logoImageView, titleStackView, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let logoCenterY = logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        logoCenterYConstraint = logoCenterY

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoCenterY,
            logoImageView.widthAnchor.constraint(equalToConstant: 96),
            logoImageView.heightAnchor.constraint(equalToConstant: 96),

            titleStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleStackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func runIntro() {
        let letters = titleStackView.arrangedSubviews

        guard !UIAccessibility.isReduceMotionEnabled else {
            // Reduce Motion: show the finished frame, hold briefly, move on.
            logoCenterYConstraint?.constant = Self.logoRestingOffset
            subtitleLabel.alpha = 1
            letters.forEach { $0.alpha = 1 }
            finish(after: 0.8)
            return
        }

        logoCenterYConstraint?.constant = Self.logoRestingOffset
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4) {
            self.view.layoutIfNeeded()
        }

        for (index, letter) in letters.enumerated() {
            letter.transform = CGAffineTransform(translationX: 0, y: 10)
            UIView.animate(withDuration: 0.28, delay: 0.35 + Double(index) * 0.055, options: [.curveEaseOut]) {
                letter.alpha = 1
                letter.transform = .identity
            }
        }

        let lettersEnd = 0.35 + Double(letters.count) * 0.055
        UIView.animate(withDuration: 0.3, delay: lettersEnd, options: [.curveEaseOut]) {
            self.subtitleLabel.alpha = 1
        }

        finish(after: lettersEnd + 0.7)
    }

    /// Where the logo settles above the wordmark.
    private static let logoRestingOffset: CGFloat = -60

    private func finish(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.onFinished?()
        }
    }
}
