import UIKit

/// Fake, non-blocking progress (spec 02 §2.1): eases 0 → 90 % over 8 s, then
/// holds. Frame-based and sized in its own `layoutSubviews`, where its bounds
/// are valid; a parent cell's `layoutSubviews` runs before this view has a width.
final class ProgressBarView: UIView {
    private static let targetFraction: CGFloat = 0.9

    private let fillView = UIView()
    private var fraction: CGFloat = 0
    private var hasStarted = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.Colors.cardBackground
        layer.cornerRadius = Theme.Spacing.progressBarRadius
        clipsToBounds = true
        fillView.backgroundColor = Theme.Colors.progressOrange
        fillView.layer.cornerRadius = Theme.Spacing.progressBarRadius
        addSubview(fillView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        fillView.layer.removeAllAnimations()
        hasStarted = false
        fraction = 0
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, !hasStarted, window != nil else {
            fillView.frame = fillFrame()
            return
        }
        hasStarted = true
        fillView.frame = fillFrame()
        fraction = Self.targetFraction

        guard !UIAccessibility.isReduceMotionEnabled else {
            fillView.frame = fillFrame()
            return
        }
        UIView.animate(withDuration: 8, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.fillView.frame = self.fillFrame()
        }
    }

    private func fillFrame() -> CGRect {
        CGRect(x: 0, y: 0, width: bounds.width * fraction, height: bounds.height)
    }
}
