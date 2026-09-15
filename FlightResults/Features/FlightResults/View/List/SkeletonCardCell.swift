import UIKit

/// Spec 05 §3.4. Loading-only placeholder for `FlightCardCell`; no data, all
/// three items in the list look identical.
final class SkeletonCardCell: UICollectionViewCell {
    static let reuseIdentifier = "SkeletonCardCell"

    private let gradientLayer = CAGradientLayer()
    private let circleView = UIView()
    private let line1View = UIView()
    private let line2View = UIView()
    private let pillView = UIView()
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
        updateShimmerMask()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        shimmerView.restart()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            shimmerView.restart()
        }
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

        [circleView, line1View, line2View, pillView].forEach {
            $0.backgroundColor = Theme.Colors.brandBlue
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        circleView.layer.cornerRadius = 12
        line1View.layer.cornerRadius = 4
        line2View.layer.cornerRadius = 4
        pillView.layer.cornerRadius = 4

        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerView)

        NSLayoutConstraint.activate([
            circleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            circleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            circleView.widthAnchor.constraint(equalToConstant: 24),
            circleView.heightAnchor.constraint(equalToConstant: 24),

            line1View.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            line1View.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
            line1View.widthAnchor.constraint(equalToConstant: 200),
            line1View.heightAnchor.constraint(equalToConstant: 8),

            line2View.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 48),
            line2View.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            line2View.widthAnchor.constraint(equalToConstant: 100),
            line2View.heightAnchor.constraint(equalToConstant: 8),

            pillView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pillView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 76),
            pillView.widthAnchor.constraint(equalToConstant: 48),
            pillView.heightAnchor.constraint(equalToConstant: 16),

            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 116)
        ])
    }

    /// The sweep is masked to the union of the block shapes, not the whole
    /// card, so it reads as one continuous highlight moving across them.
    private func updateShimmerMask() {
        let path = CGMutablePath()
        path.addPath(UIBezierPath(roundedRect: circleView.frame, cornerRadius: 12).cgPath)
        path.addPath(UIBezierPath(roundedRect: line1View.frame, cornerRadius: 4).cgPath)
        path.addPath(UIBezierPath(roundedRect: line2View.frame, cornerRadius: 4).cgPath)
        path.addPath(UIBezierPath(roundedRect: pillView.frame, cornerRadius: 4).cgPath)
        shimmerView.setMaskPath(path)
    }
}
