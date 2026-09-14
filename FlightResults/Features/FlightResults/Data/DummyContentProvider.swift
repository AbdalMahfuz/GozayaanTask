import Foundation

/// The brief's required dummy content: promotions and date-strip fares
/// (spec 03 §3, D-21, D-30).
struct DummyContentProvider: Sendable {
    let promotions: [Promotion]
    let dateFares: [DateFare]

    static func make(searchDate: Date) -> DummyContentProvider {
        DummyContentProvider(promotions: makePromotions(), dateFares: makeDateFares(around: searchDate))
    }

    private static func makePromotions() -> [Promotion] {
        let url = URL(string: "https://www.gozayaan.com")!
        return (0..<3).map { index in
            Promotion(
                id: "promo-\(index)",
                imageName: "promo_discount",
                title: "On International Flight Bookings",
                url: url
            )
        }
    }

    private static func makeDateFares(around searchDate: Date) -> [DateFare] {
        let prices = [70129, 74240, 120400, 68500, 81990, 95300, 77410]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return prices.enumerated().map { index, price in
            let dayOffset = index - 3
            let date = calendar.date(byAdding: .day, value: dayOffset, to: searchDate) ?? searchDate
            return DateFare(date: date, price: price, isSelected: index == 3)
        }
    }
}
