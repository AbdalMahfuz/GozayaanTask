import UIKit

/// A looping left-to-right shimmer sweep (spec 05 §3.4). Used both as a
/// self-clipped rounded bar (date-strip fare shimmer) and, via `maskPath`,
/// as an overlay masked to an arbitrary union of shapes (skeleton blocks).
///
/// Restarts on `didMoveToWindow` (first attach) and on
/// `willEnterForegroundNotification`, since a `CABasicAnimation` doesn't
/// survive the app leaving the foreground. Cell reuse doesn't trigger
/// `didMoveToWindow`, so reused cells must call `restart()` explicitly
/// (from `prepareForReuse`).
final class ShimmerView: UIView {
    private let gradientLayer = CAGradientLayer()
    private static let fromLocations: [NSNumber] = [-1, -0.5, 0]
    private static let toLocations: [NSNumber] = [1, 1.5, 2]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = Self.fromLocations
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
        NotificationCenter.default.addObserver(
            self, selector: #selector(restart),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Restricts the sweep to this path (view-local coordinates), for a
    /// discontiguous union of shapes. Leave unset to clip to the view's own
    /// bounds/corner radius instead.
    func setMaskPath(_ path: CGPath?) {
        guard let path else {
            layer.mask = nil
            return
        }
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            restart()
        } else {
            gradientLayer.removeAnimation(forKey: Self.animationKey)
        }
    }

    @objc func restart() {
        gradientLayer.removeAnimation(forKey: Self.animationKey)
        guard window != nil else { return }
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = Self.fromLocations
        animation.toValue = Self.toLocations
        animation.duration = 1.2
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: Self.animationKey)
    }

    private static let animationKey = "shimmerSweep"
}
