import XCTest
@testable import FlightResults

final class FlightOfferSorterTests: XCTestCase {
    func test_cheapest_withTieBreaks() {
        let cheap = FlightOffer.fake(id: "cheap", totalDurationMinutes: 300, price: 100)
        let sameCheapButFaster = FlightOffer.fake(id: "sameCheapButFaster", totalDurationMinutes: 200, price: 100)
        let expensive = FlightOffer.fake(id: "expensive", totalDurationMinutes: 100, price: 300)

        let sorted = FlightOfferSorter.sort([expensive, cheap, sameCheapButFaster], by: .cheapest)
        XCTAssertEqual(sorted.map(\.id), ["sameCheapButFaster", "cheap", "expensive"])
    }

    func test_fastest_withTieBreaks() {
        let fast = FlightOffer.fake(id: "fast", totalDurationMinutes: 100, price: 300)
        let sameFastButCheaper = FlightOffer.fake(id: "sameFastButCheaper", totalDurationMinutes: 100, price: 100)
        let slow = FlightOffer.fake(id: "slow", totalDurationMinutes: 400, price: 50)

        let sorted = FlightOfferSorter.sort([slow, fast, sameFastButCheaper], by: .fastest)
        XCTAssertEqual(sorted.map(\.id), ["sameFastButCheaper", "fast", "slow"])
    }

    func test_sort_isStable() {
        let offers = (0..<5).map { FlightOffer.fake(id: "\($0)", totalDurationMinutes: 100, price: 100) }
        let sorted = FlightOfferSorter.sort(offers, by: .cheapest)
        XCTAssertEqual(sorted.map(\.id), offers.map(\.id))
    }

    func test_departureTime_isTieBreakBeforeOriginalOrder() {
        let later = FlightOffer.fake(
            id: "later", departure: LocalDateTime(year: 2026, month: 2, day: 15, hour: 10, minute: 0),
            totalDurationMinutes: 100, price: 100
        )
        let earlier = FlightOffer.fake(
            id: "earlier", departure: LocalDateTime(year: 2026, month: 2, day: 15, hour: 6, minute: 0),
            totalDurationMinutes: 100, price: 100
        )
        let sorted = FlightOfferSorter.sort([later, earlier], by: .cheapest)
        XCTAssertEqual(sorted.map(\.id), ["earlier", "later"])
    }
}
