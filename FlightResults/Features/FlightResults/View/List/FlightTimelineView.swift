import UIKit

/// Spec 05 §3.1 "FlightTimelineView": a line between two end circles, plus
/// `stopDotCount` dots spread evenly along it.
final class FlightTimelineView: UIView {
    var dotCount: Int = 0 {
        didSet {
            guard dotCount != oldValue else { return }
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let color = Theme.Colors.brandBlue
        let midY = rect.midY
        let endRadius: CGFloat = 4
        let dotRadius: CGFloat = 3.5

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: rect.minX + endRadius, y: midY))
        context.addLine(to: CGPoint(x: rect.maxX - endRadius, y: midY))
        context.strokePath()

        for x in [rect.minX + endRadius, rect.maxX - endRadius] {
            let circleRect = CGRect(x: x - endRadius, y: midY - endRadius, width: endRadius * 2, height: endRadius * 2)
            context.setFillColor(UIColor.white.cgColor)
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(1.5)
            context.addEllipse(in: circleRect)
            context.drawPath(using: .fillStroke)
        }

        context.setFillColor(color.cgColor)
        for fraction in dotPositions(for: dotCount) {
            let x = rect.minX + rect.width * fraction
            let dotRect = CGRect(x: x - dotRadius, y: midY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            context.fillEllipse(in: dotRect)
        }
    }

    private func dotPositions(for count: Int) -> [CGFloat] {
        switch count {
        case 0: return []
        case 1: return [0.5]
        case 2: return [0.45, 0.55]
        default: return [0.25, 0.5, 0.75]
        }
    }
}
