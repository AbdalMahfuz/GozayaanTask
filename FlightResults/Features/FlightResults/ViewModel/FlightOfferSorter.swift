import Foundation

/// Pure, stable sort (spec 03 §5). `sorted(by:)` isn't guaranteed stable, so
/// this sorts on `enumerated()` with the original index as the last tie-break.
enum FlightOfferSorter {
    static func sort(_ offers: [FlightOffer], by option: SortOption) -> [FlightOffer] {
        offers.enumerated()
            .sorted { isOrderedBefore($0, $1, option: option) }
            .map(\.element)
    }

    private static func isOrderedBefore(
        _ lhs: (offset: Int, element: FlightOffer),
        _ rhs: (offset: Int, element: FlightOffer),
        option: SortOption
    ) -> Bool {
        let (primary, secondary): (KeyPath<FlightOffer, Int>, KeyPath<FlightOffer, Int>)
        switch option {
        case .cheapest:
            (primary, secondary) = (\.price, \.totalDurationMinutes)
        case .fastest:
            (primary, secondary) = (\.totalDurationMinutes, \.price)
        }

        let lp = lhs.element[keyPath: primary], rp = rhs.element[keyPath: primary]
        if lp != rp { return lp < rp }

        let ls = lhs.element[keyPath: secondary], rs = rhs.element[keyPath: secondary]
        if ls != rs { return ls < rs }

        let lDeparture = lhs.element.departure.localDateTime, rDeparture = rhs.element.departure.localDateTime
        if lDeparture != rDeparture { return lDeparture < rDeparture }

        return lhs.offset < rhs.offset
    }
}
