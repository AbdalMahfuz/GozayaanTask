import Foundation

/// Date → `"Sun 08 Feb"` (`EEE dd MMM`, `en_US_POSIX`, UTC — spec 03 §6, D-17).
struct ChipDateFormatter: @unchecked Sendable {
    // Same `DateFormatter`-isn't-`Sendable` reasoning as `FlightOfferMapper`.
    private let dateFormatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "EEE dd MMM"
        dateFormatter = formatter
    }

    func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
