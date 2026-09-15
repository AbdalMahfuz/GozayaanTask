import UIKit

/// Spec 05 §3.4. Loading-only placeholder for `FlightCardCell`; no data, all
/// three items in the list look identical.
final class SkeletonCardCell: UICollectionViewCell {
    static let reuseIdentifier = "SkeletonCardCell"

    // Fixed geometry from the spec (points from the card's top-left). The
    // shimmer mask is built from these constants, not from subview frames:
    // those are still zero when the cell's own `layoutSubviews` runs.
    private enum Block {
        static let circle = CGRect(x: 16, y: 24, width: 24, height: 24)
        static let line1 = CGRect(x: 48, y: 26, width: 200, height: 8)
        static let line2 = CGRect(x: 48, y: 40, width: 100, height: 8)
        static let pill = CGRect(x: 16, y: 76, width: 48, height: 16)
    }

    private let gradientLayer = CAGradientLayer()
    private let shimmerView = ShimmerView()

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
        gradientLayer.frame = contentView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        shimmerView.restart()
    }

    private func setUp() {
        isUserInteractionEnabled = false
        contentView.accessibilityElementsHidden = true

        contentView.layer.cornerRadius = Theme.Spacing.skeletonRadius
        contentView.clipsToBounds = true
        gradientLayer.colors = [Theme.Colors.skeletonStart.cgColor, Theme.Colors.skeletonEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        let blocks: [(CGRect, CGFloat)] = [
            (Block.circle, 12), (Block.line1, 4), (Block.line2, 4), (Block.pill, 4)
        ]
        let maskPath = CGMutablePath()
        for (rect, radius) in blocks {
            let blockView = UIView()
            blockView.backgroundColor = Theme.Colors.brandBlue
            blockView.layer.cornerRadius = radius
            blockView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(blockView)
            NSLayoutConstraint.activate([
                blockView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: rect.minX),
                blockView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: rect.minY),
                blockView.widthAnchor.constraint(equalToConstant: rect.width),
                blockView.heightAnchor.constraint(equalToConstant: rect.height)
            ])
            maskPath.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        }

        // The overlay shares the content view's origin, so the block rects
        // are already in its coordinate space.
        shimmerView.setMaskPath(maskPath)
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerView)

        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 116)
        ])
    }
}
