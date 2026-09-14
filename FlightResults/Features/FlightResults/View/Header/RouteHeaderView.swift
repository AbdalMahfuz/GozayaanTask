import UIKit

/// Spec 05 §2.1. Decorative back chevron; no Edit button (D-19).
final class RouteHeaderView: UIView {
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: RouteHeaderViewData) {
        titleLabel.text = data.title
        subtitleLabel.attributedText = Self.makeSubtitle(data: data)
        accessibilityLabel = "\(data.title). \(data.dateText). \(data.passengerText) passengers. \(data.tripTypeText)."
    }

    private func setUp() {
        backgroundColor = .clear
        isAccessibilityElement = false

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = Theme.Colors.onNavy
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.accessibilityLabel = "Back"
        backButton.accessibilityTraits = .button
        // Decorative: no target added — tapping does nothing (D-19).

        titleLabel.font = Theme.Typography.headerTitle
        titleLabel.textColor = Theme.Colors.onNavy
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 1

        [backButton, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private static func makeSubtitle(data: RouteHeaderViewData) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Theme.Typography.headerSubtitle,
            .foregroundColor: Theme.Colors.onNavy
        ]
        let result = NSMutableAttributedString(string: "\(data.dateText)  |  ", attributes: attributes)

        if let personImage = UIImage(systemName: "person")?
            .withTintColor(Theme.Colors.onNavy, renderingMode: .alwaysOriginal) {
            let attachment = NSTextAttachment()
            attachment.image = personImage
            let pointSize: CGFloat = 12
            let ratio = personImage.size.width / max(personImage.size.height, 1)
            attachment.bounds = CGRect(x: 0, y: -1, width: pointSize * ratio, height: pointSize)
            result.append(NSAttributedString(attachment: attachment))
        }

        result.append(NSAttributedString(string: "  \(data.passengerText)  |  \(data.tripTypeText)", attributes: attributes))
        return result
    }
}
