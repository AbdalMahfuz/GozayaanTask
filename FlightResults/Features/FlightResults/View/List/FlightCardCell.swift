import UIKit

/// Spec 05 §3.1. All formatting happens upstream in the ViewModel — this
/// cell only lays out already-formatted strings (R11).
final class FlightCardCell: UICollectionViewCell {
    static let reuseIdentifier = "FlightCardCell"

    private let containerView = UIView()

    private let logoImageView = UIImageView()
    private let airlineLabel = UILabel()
    private let coinImageView = UIImageView()
    private let pointsLabel = UILabel()

    private let departureTimeLabel = UILabel()
    private let departureCodeLabel = UILabel()

    private let durationLabel = UILabel()
    private let timelineView = FlightTimelineView()
    private let stopsLabel = UILabel()

    private let arrivalTimeLabel = UILabel()
    private let dayOffsetLabel = UILabel()
    private let arrivalCodeLabel = UILabel()

    private let dashedLineView = DashedLineView()
    private let startingFromLabel = UILabel()
    private let currencyLabel = UILabel()
    private let priceLabel = UILabel()

    private var dayOffsetVisibleConstraints: [NSLayoutConstraint] = []
    private var dayOffsetHiddenConstraints: [NSLayoutConstraint] = []

    private var imageLoadTask: Task<Void, Never>?

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
                self.containerView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97)
                    : .identity
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        logoImageView.image = Self.placeholderLogo
    }

    func configure(with data: FlightCardViewData, imageLoader: ImageLoading?) {
        airlineLabel.text = data.airlineText
        pointsLabel.text = "Get Points"

        departureTimeLabel.text = data.departureTime
        departureCodeLabel.text = data.departureCode

        durationLabel.text = data.durationText
        timelineView.dotCount = data.stopDotCount
        stopsLabel.text = data.stopsText

        arrivalTimeLabel.text = data.arrivalTime
        arrivalCodeLabel.text = data.arrivalCode
        setDayOffset(data.arrivalDayOffsetText)

        startingFromLabel.text = "Starting from"
        currencyLabel.text = data.currencyCode
        priceLabel.text = data.priceText

        isAccessibilityElement = true
        accessibilityLabel = data.accessibilityLabel
        accessibilityTraits = .button

        imageLoadTask?.cancel()
        logoImageView.image = Self.placeholderLogo
        if let url = data.airlineLogoURL, let imageLoader {
            imageLoadTask = Task { [weak self] in
                let image = await imageLoader.loadImage(from: url)
                guard !Task.isCancelled else { return }
                self?.logoImageView.image = image ?? Self.placeholderLogo
            }
        }
    }

    private func setDayOffset(_ text: String?) {
        dayOffsetLabel.text = text
        let isVisible = text != nil
        dayOffsetLabel.isHidden = !isVisible
        dayOffsetVisibleConstraints.forEach { $0.isActive = isVisible }
        dayOffsetHiddenConstraints.forEach { $0.isActive = !isVisible }
    }

    private static var placeholderLogo: UIImage? {
        UIImage(systemName: "airplane.circle.fill")?.withTintColor(.systemGray4, renderingMode: .alwaysOriginal)
    }

    // MARK: - Layout

    private func setUp() {
        contentView.backgroundColor = .clear
        setUpContainer()
        setUpRow1()
        setUpRow2()
        setUpSeparatorAndPrice()
    }

    private func setUpContainer() {
        containerView.backgroundColor = Theme.Colors.cardBackground
        containerView.layer.cornerRadius = Theme.Spacing.cardRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setUpRow1() {
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = 4
        logoImageView.clipsToBounds = true
        logoImageView.image = Self.placeholderLogo
        logoImageView.backgroundColor = .systemGray5

        airlineLabel.font = Theme.Typography.airline
        airlineLabel.textColor = Theme.Colors.textPrimary
        airlineLabel.numberOfLines = 1
        airlineLabel.lineBreakMode = .byTruncatingTail
        airlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        airlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        coinImageView.image = UIImage(systemName: "bitcoinsign.circle.fill")?
            .withTintColor(Theme.Colors.yellow, renderingMode: .alwaysOriginal)
        coinImageView.contentMode = .scaleAspectFit

        pointsLabel.font = Theme.Typography.points
        pointsLabel.textColor = Theme.Colors.textSecondary
        pointsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row1Stack = UIStackView(arrangedSubviews: [logoImageView, airlineLabel, coinImageView, pointsLabel])
        row1Stack.axis = .horizontal
        row1Stack.alignment = .center
        row1Stack.spacing = 8
        row1Stack.setCustomSpacing(6, after: coinImageView)
        row1Stack.translatesAutoresizingMaskIntoConstraints = false
        row1Stack.tag = Tag.row1Stack.rawValue
        containerView.addSubview(row1Stack)

        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 20),
            logoImageView.heightAnchor.constraint(equalToConstant: 20),
            coinImageView.widthAnchor.constraint(equalToConstant: 18),
            coinImageView.heightAnchor.constraint(equalToConstant: 18),

            row1Stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Theme.Spacing.cardPadding),
            row1Stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Theme.Spacing.cardPadding),
            row1Stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Theme.Spacing.cardPadding)
        ])
    }

    private func setUpRow2() {
        durationLabel.font = Theme.Typography.meta
        durationLabel.textColor = Theme.Colors.textSecondary
        stopsLabel.font = Theme.Typography.meta
        stopsLabel.textColor = Theme.Colors.textSecondary

        departureTimeLabel.font = Theme.Typography.time
        departureTimeLabel.textColor = Theme.Colors.textPrimary
        departureCodeLabel.font = Theme.Typography.airportCode
        departureCodeLabel.textColor = Theme.Colors.textSecondary

        arrivalTimeLabel.font = Theme.Typography.time
        arrivalTimeLabel.textColor = Theme.Colors.textPrimary
        arrivalCodeLabel.font = Theme.Typography.airportCode
        arrivalCodeLabel.textColor = Theme.Colors.textSecondary
        dayOffsetLabel.font = Theme.Typography.dayOffset
        dayOffsetLabel.textColor = Theme.Colors.dayOffsetRed

        let centerColumn = UIView()
        centerColumn.tag = Tag.centerColumn.rawValue

        let row2Bottom = UIView() // 0-height marker so the separator sits below the tallest column
        row2Bottom.tag = Tag.row2Bottom.rawValue

        [departureTimeLabel, departureCodeLabel, centerColumn, durationLabel, timelineView, stopsLabel,
         arrivalTimeLabel, dayOffsetLabel, arrivalCodeLabel, row2Bottom].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        containerView.addSubview(departureTimeLabel)
        containerView.addSubview(departureCodeLabel)
        containerView.addSubview(centerColumn)
        centerColumn.addSubview(durationLabel)
        centerColumn.addSubview(timelineView)
        centerColumn.addSubview(stopsLabel)
        containerView.addSubview(arrivalTimeLabel)
        containerView.addSubview(dayOffsetLabel)
        containerView.addSubview(arrivalCodeLabel)
        containerView.addSubview(row2Bottom)

        guard let row1Stack = containerView.viewWithTag(Tag.row1Stack.rawValue) else { return }

        NSLayoutConstraint.activate([
            departureTimeLabel.topAnchor.constraint(equalTo: row1Stack.bottomAnchor, constant: 16),
            departureTimeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Theme.Spacing.cardPadding),
            departureCodeLabel.topAnchor.constraint(equalTo: departureTimeLabel.bottomAnchor, constant: 4),
            departureCodeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Theme.Spacing.cardPadding),
            departureTimeLabel.trailingAnchor.constraint(lessThanOrEqualTo: centerColumn.leadingAnchor, constant: -8),
            departureCodeLabel.trailingAnchor.constraint(lessThanOrEqualTo: centerColumn.leadingAnchor, constant: -8),

            centerColumn.topAnchor.constraint(equalTo: row1Stack.bottomAnchor, constant: 16),
            centerColumn.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerColumn.widthAnchor.constraint(equalToConstant: 100),

            durationLabel.topAnchor.constraint(equalTo: centerColumn.topAnchor),
            durationLabel.centerXAnchor.constraint(equalTo: centerColumn.centerXAnchor),
            timelineView.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 6),
            timelineView.centerXAnchor.constraint(equalTo: centerColumn.centerXAnchor),
            timelineView.widthAnchor.constraint(equalToConstant: 92),
            timelineView.heightAnchor.constraint(equalToConstant: 8),
            stopsLabel.topAnchor.constraint(equalTo: timelineView.bottomAnchor, constant: 6),
            stopsLabel.centerXAnchor.constraint(equalTo: centerColumn.centerXAnchor),
            stopsLabel.bottomAnchor.constraint(equalTo: centerColumn.bottomAnchor),

            arrivalTimeLabel.topAnchor.constraint(equalTo: row1Stack.bottomAnchor, constant: 16),
            arrivalTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: centerColumn.trailingAnchor, constant: 8),
            dayOffsetLabel.topAnchor.constraint(equalTo: arrivalTimeLabel.topAnchor),
            dayOffsetLabel.leadingAnchor.constraint(equalTo: arrivalTimeLabel.trailingAnchor, constant: 1),
            arrivalCodeLabel.topAnchor.constraint(equalTo: arrivalTimeLabel.bottomAnchor, constant: 4),
            arrivalCodeLabel.trailingAnchor.constraint(equalTo: arrivalTimeLabel.trailingAnchor),

            row2Bottom.topAnchor.constraint(greaterThanOrEqualTo: departureCodeLabel.bottomAnchor),
            row2Bottom.topAnchor.constraint(greaterThanOrEqualTo: centerColumn.bottomAnchor),
            row2Bottom.topAnchor.constraint(greaterThanOrEqualTo: arrivalCodeLabel.bottomAnchor),
            row2Bottom.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            row2Bottom.heightAnchor.constraint(equalToConstant: 0)
        ])

        dayOffsetVisibleConstraints = [
            dayOffsetLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Theme.Spacing.cardPadding)
        ]
        dayOffsetHiddenConstraints = [
            arrivalTimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Theme.Spacing.cardPadding)
        ]
        // Default state: no offset.
        dayOffsetHiddenConstraints.forEach { $0.isActive = true }
    }

    private func setUpSeparatorAndPrice() {
        startingFromLabel.font = Theme.Typography.meta
        startingFromLabel.textColor = Theme.Colors.textSecondary
        startingFromLabel.textAlignment = .right

        currencyLabel.font = Theme.Typography.currency
        currencyLabel.textColor = Theme.Colors.textSecondary
        priceLabel.font = Theme.Typography.price
        priceLabel.textColor = Theme.Colors.navy

        let priceRow = UIStackView(arrangedSubviews: [currencyLabel, priceLabel])
        priceRow.axis = .horizontal
        priceRow.alignment = .lastBaseline
        priceRow.spacing = 6

        let priceStack = UIStackView(arrangedSubviews: [startingFromLabel, priceRow])
        priceStack.axis = .vertical
        priceStack.alignment = .trailing
        priceStack.spacing = 4
        priceStack.translatesAutoresizingMaskIntoConstraints = false

        guard let row2Bottom = containerView.viewWithTag(Tag.row2Bottom.rawValue) else { return }

        dashedLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dashedLineView)
        containerView.addSubview(priceStack)

        NSLayoutConstraint.activate([
            dashedLineView.topAnchor.constraint(equalTo: row2Bottom.topAnchor, constant: 16),
            dashedLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Theme.Spacing.cardPadding),
            dashedLineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Theme.Spacing.cardPadding),
            dashedLineView.heightAnchor.constraint(equalToConstant: 1),

            priceStack.topAnchor.constraint(equalTo: dashedLineView.bottomAnchor, constant: 12),
            priceStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Theme.Spacing.cardPadding),
            priceStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Theme.Spacing.cardPadding)
        ])
    }

    private enum Tag: Int {
        case row1Stack = 1001
        case centerColumn = 1002
        case row2Bottom = 1003
    }
}
