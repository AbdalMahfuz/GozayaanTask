import UIKit

/// Spec 05 §2.2. Width / height from Figma fare chips; set by the collection view's layout.
final class DateFareChipCell: UICollectionViewCell {
    static let reuseIdentifier = "DateFareChipCell"

    private let dateLabel = UILabel()
    private let priceLabel = UILabel()
    private let shimmerBar = ShimmerView()
    private let selectionIndicator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: DateFareViewData, isLoading: Bool) {
        dateLabel.text = data.dateText
        priceLabel.text = data.priceText

        let color = data.isSelected ? Theme.Colors.yellow : Theme.Colors.onNavy
        dateLabel.textColor = color
        priceLabel.textColor = color
        selectionIndicator.isHidden = !data.isSelected

        priceLabel.isHidden = isLoading
        shimmerBar.isHidden = !isLoading
        if isLoading {
            shimmerBar.restart()
        }

        isAccessibilityElement = true
        accessibilityLabel = isLoading ? "\(data.dateText), fare loading" : "\(data.dateText), \(data.priceText)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        priceLabel.isHidden = false
        shimmerBar.isHidden = true
        selectionIndicator.isHidden = true
    }

    private func setUp() {
        dateLabel.font = Theme.Typography.chipDate
        dateLabel.textAlignment = .center

        priceLabel.font = Theme.Typography.chipPrice
        priceLabel.textAlignment = .center

        shimmerBar.backgroundColor = Theme.Colors.brandBlue
        shimmerBar.layer.cornerRadius = 4
        shimmerBar.clipsToBounds = true
        shimmerBar.isHidden = true

        selectionIndicator.backgroundColor = Theme.Colors.yellow
        selectionIndicator.isHidden = true

        [dateLabel, priceLabel, shimmerBar, selectionIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            priceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            shimmerBar.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            shimmerBar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shimmerBar.widthAnchor.constraint(equalToConstant: 80),
            shimmerBar.heightAnchor.constraint(equalToConstant: 12),

            selectionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: Theme.Spacing.chipIndicatorHeight)
        ])
    }
}
