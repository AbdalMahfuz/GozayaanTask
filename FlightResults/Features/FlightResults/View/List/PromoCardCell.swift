import UIKit

/// Spec 05 §3.2. The whole cell is tappable (forwarded via the collection
/// view's selection delegate, not a per-cell closure — the View only calls
/// ViewModel intents).
final class PromoCardCell: UICollectionViewCell {
    static let reuseIdentifier = "PromoCardCell"

    private let imageAreaView = UIView()
    private let promoImageView = UIImageView()
    private let contentAreaView = UIView()
    private let titleLabel = UILabel()
    private let learnMoreLabel = UILabel()
    private let arrowImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.contentView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97)
                    : .identity
            }
        }
    }

    func configure(with data: PromotionViewData) {
        titleLabel.text = data.title
        promoImageView.image = UIImage(named: data.imageName)

        let learnMoreAttributes: [NSAttributedString.Key: Any] = [
            .font: Theme.Typography.promoLink,
            .foregroundColor: Theme.Colors.textSecondary,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        learnMoreLabel.attributedText = NSAttributedString(string: data.linkText, attributes: learnMoreAttributes)

        isAccessibilityElement = true
        accessibilityLabel = "\(data.title). \(data.linkText), opens gozayaan.com"
        accessibilityTraits = .link
    }

    private func setUp() {
        contentView.layer.cornerRadius = Theme.Spacing.promoRadius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.clipsToBounds = true

        imageAreaView.backgroundColor = Theme.Colors.navy
        promoImageView.contentMode = .scaleAspectFit

        contentAreaView.backgroundColor = Theme.Colors.promoMint

        titleLabel.font = Theme.Typography.promoTitle
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        arrowImageView.image = UIImage(systemName: "arrow.up.right")?
            .applyingSymbolConfiguration(.init(pointSize: 8))
        arrowImageView.tintColor = Theme.Colors.textSecondary
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let learnMoreStack = UIStackView(arrangedSubviews: [learnMoreLabel, arrowImageView])
        learnMoreStack.axis = .horizontal
        learnMoreStack.spacing = 2
        learnMoreStack.alignment = .center

        [imageAreaView, contentAreaView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        promoImageView.translatesAutoresizingMaskIntoConstraints = false
        imageAreaView.addSubview(promoImageView)

        [titleLabel, learnMoreStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentAreaView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            imageAreaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageAreaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageAreaView.widthAnchor.constraint(equalToConstant: 64),

            promoImageView.centerXAnchor.constraint(equalTo: imageAreaView.centerXAnchor),
            promoImageView.centerYAnchor.constraint(equalTo: imageAreaView.centerYAnchor),
            promoImageView.widthAnchor.constraint(lessThanOrEqualTo: imageAreaView.widthAnchor, constant: -8),
            promoImageView.heightAnchor.constraint(lessThanOrEqualTo: imageAreaView.heightAnchor, constant: -8),

            contentAreaView.leadingAnchor.constraint(equalTo: imageAreaView.trailingAnchor),
            contentAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentAreaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentAreaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentAreaView.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentAreaView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentAreaView.trailingAnchor, constant: -8),

            learnMoreStack.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 2),
            learnMoreStack.leadingAnchor.constraint(equalTo: contentAreaView.leadingAnchor, constant: 12),
            learnMoreStack.bottomAnchor.constraint(equalTo: contentAreaView.bottomAnchor, constant: -6)
        ])
    }
}
