import Foundation

/// `(Int, currencyCode)` → `"37,400"` / `"BDT 37,400"` (spec 03 §6).
struct PriceFormatter: @unchecked Sendable {
    // `NumberFormatter` isn't `Sendable`; created once per instance, never
    // per call (same reasoning as `FlightOfferMapper`'s `DateFormatter`).
    private let numberFormatter: NumberFormatter

    init() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        numberFormatter = formatter
    }

    func amount(_ price: Int) -> String {
        numberFormatter.string(from: NSNumber(value: price)) ?? String(price)
    }

    func full(_ price: Int, currencyCode: String) -> String {
        "\(currencyCode) \(amount(price))"
    }
}
