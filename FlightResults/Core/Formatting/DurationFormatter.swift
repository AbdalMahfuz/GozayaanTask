import Foundation

/// Minutes → `"4h 40m"` / `"5h"` / `"45m"` (spec 03 §6).
struct DurationFormatter {
    func string(from minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        switch (hours, remainder) {
        case (0, let m):
            return "\(m)m"
        case (let h, 0):
            return "\(h)h"
        default:
            return "\(hours)h \(remainder)m"
        }
    }
}
