import UIKit

/// Spec 05 §2.2. Width 100 / height 64, set by the collection view's layout.
final class DateFareChipCell: UICollectionViewCell {
    static let reuseIdentifier = "DateFareChipCell"

    private let dateLabel = UILabel()
    private let priceLabel = UILabel()
    private let shimmerBar = UIView()
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

        shimmerBar.backgroundColor = Theme.Colors.onNavy.withAlphaComponent(0.3)
        shimmerBar.layer.cornerRadius = 6
        shimmerBar.isHidden = true

        selectionIndicator.backgroundColor = Theme.Colors.yellow
        selectionIndicator.isHidden = true

        [dateLabel, priceLabel, shimmerBar, selectionIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            priceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 6),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            shimmerBar.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            shimmerBar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shimmerBar.widthAnchor.constraint(equalToConstant: 70),
            shimmerBar.heightAnchor.constraint(equalToConstant: 12),

            selectionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 3)
        ])
    }
}
