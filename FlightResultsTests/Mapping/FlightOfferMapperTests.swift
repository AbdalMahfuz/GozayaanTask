import XCTest
@testable import FlightResults

final class FlightOfferMapperTests: XCTestCase {
    private let mapper = FlightOfferMapper()

    private let request = FlightSearchRequest(
        originCode: "DAC",
        destinationCode: "JFK",
        originCity: "Dhaka",
        destinationCity: "New York",
        outboundDate: Date(timeIntervalSince1970: 1_760_400_000),
        adults: 2,
        currencyCode: "BDT",
        tripType: .oneWay
    )

    private func map(_ fixture: String) throws -> [FlightOffer] {
        let response = try JSONDecoder.serpApi.decode(
            SerpApiFlightsResponse.self,
            from: FixtureLoader.data(named: fixture)
        )
        return mapper.map(response, request: request)
    }

    func test_nonStop() throws {
        let offers = try map("nonstop")
        XCTAssertEqual(offers.count, 1)
        let offer = try XCTUnwrap(offers.first)
        XCTAssertEqual(offer.departure.airportCode, "DAC")
        XCTAssertEqual(offer.departure.localDateTime, LocalDateTime(year: 2026, month: 2, day: 15, hour: 12, minute: 30))
        XCTAssertEqual(offer.arrival.airportCode, "BKK")
        XCTAssertEqual(offer.arrival.localDateTime, LocalDateTime(year: 2026, month: 2, day: 15, hour: 16, minute: 50))
        XCTAssertEqual(offer.stops, 0)
        XCTAssertEqual(offer.totalDurationMinutes, 280)
        XCTAssertEqual(offer.price, 37400)
        XCTAssertEqual(offer.arrivalDayOffset, 0)
    }

    func test_oneStop_overnight() throws {
        let offers = try map("one_stop_overnight")
        XCTAssertEqual(offers.count, 1)
        let offer = try XCTUnwrap(offers.first)
        XCTAssertEqual(offer.stops, 1)
        XCTAssertEqual(offer.arrivalDayOffset, 1)
        XCTAssertEqual(offer.departure.airportCode, "DAC")
        XCTAssertEqual(offer.departure.localDateTime.hour, 4)
        XCTAssertEqual(offer.arrival.airportCode, "CVB")
        XCTAssertEqual(offer.arrival.localDateTime.hour, 8)
        XCTAssertEqual(offer.arrival.localDateTime.minute, 20)
        XCTAssertEqual(offer.layoverAirportCodes, ["DXB"])
    }

    func test_threeLegs_mapsToTwoStop() throws {
        let offers = try map("two_stop_multi_airline")
        XCTAssertEqual(offers.count, 1)
        let offer = try XCTUnwrap(offers.first)
        XCTAssertEqual(offer.stops, 2)
        XCTAssertEqual(offer.arrival.airportCode, "JFK")
        XCTAssertEqual(offer.arrivalDayOffset, 2)
        XCTAssertEqual(offer.airlineNames, ["Air Arabia", "US Bangla Airlines"])
        XCTAssertEqual(offer.layoverAirportCodes, ["SHJ", "CMB"])
    }

    func test_missingTotalDuration_sumsLegsAndLayovers() throws {
        let offers = try map("missing_total_duration")
        XCTAssertEqual(offers.count, 1)
        XCTAssertEqual(offers.first?.totalDurationMinutes, 280)
    }

    func test_invalidGroups_areSkipped() throws {
        let offers = try map("invalid_groups")
        XCTAssertEqual(offers.count, 1)
        XCTAssertEqual(offers.first?.price, 35000)
    }

    func test_missingPrice_isSkipped() throws {
        let response = try JSONDecoder.serpApi.decode(
            SerpApiFlightsResponse.self,
            from: FixtureLoader.data(named: "invalid_groups")
        )
        let groupWithNoPrice = try XCTUnwrap(response.bestFlights?.first)
        XCTAssertNil(groupWithNoPrice.price)
        XCTAssertNil(mapper.mapGroup(groupWithNoPrice, source: .best, currencyCode: "BDT"))
    }

    func test_bestBeforeOther_andDeduplicates() throws {
        let offers = try map("duplicates")
        XCTAssertEqual(offers.count, 1)
        XCTAssertEqual(offers.first?.source, .best)
        XCTAssertEqual(offers.first?.price, 37400)
    }

    func test_bestBeforeOther_keepsApiOrder() throws {
        let offers = try map("best_and_other_order")
        XCTAssertEqual(offers.map(\.price), [30000, 31000, 32000, 33000])
        XCTAssertEqual(offers.map(\.source), [.best, .best, .other, .other])
    }

    func test_offerId_isStableAndUnique() throws {
        let first = try map("best_and_other_order")
        let second = try map("best_and_other_order")
        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertEqual(Set(first.map(\.id)).count, first.count)
    }

    func test_localTimes_areNotTimeZoneShifted() throws {
        let originalTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        defer { NSTimeZone.default = originalTimeZone }

        let offers = try map("nonstop")
        XCTAssertEqual(offers.first?.departure.localDateTime.hour, 12)
        XCTAssertEqual(offers.first?.departure.localDateTime.minute, 30)
    }
}
