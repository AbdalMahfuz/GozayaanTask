import Foundation

/// Int → `"01"` / `"12"` (spec 03 §6).
struct PassengerFormatter {
    func string(from adults: Int) -> String {
        String(format: "%02d", adults)
    }
}
