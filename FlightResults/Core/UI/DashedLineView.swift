import UIKit

/// A 1 pt dashed horizontal line (dash 4, gap 3), spanning its own bounds.
final class DashedLineView: UIView {
    private let dashLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        dashLayer.strokeColor = Theme.Colors.separator.cgColor
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [4, 3]
        layer.addSublayer(dashLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        dashLayer.path = path.cgPath
        dashLayer.frame = bounds
    }
}
