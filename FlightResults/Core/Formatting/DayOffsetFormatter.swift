import Foundation

/// Int → `nil` / `"+1Day"` / `"-1Day"` (spec 03 §6).
struct DayOffsetFormatter {
    func string(from dayOffset: Int) -> String? {
        guard dayOffset != 0 else { return nil }
        let sign = dayOffset > 0 ? "+" : "-"
        return "\(sign)\(abs(dayOffset))Day"
    }
}
