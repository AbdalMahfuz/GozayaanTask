import XCTest
@testable import FlightResults

/// Sanity check for the app-bundled SerpApi fixture (plan Step 6). Runs
/// hosted inside the app, so `Bundle.main` is the app bundle.
final class BundledFixtureTests: XCTestCase {
    func test_bundledFixture_mapsToAtLeastOneMultiStopOffer() async throws {
        let dataSource = FixtureFlightsDataSource(delay: .zero)
        let request = FlightSearchRequest(
            originCode: "DAC",
            destinationCode: "JFK",
            originCity: "Dhaka",
            destinationCity: "New York",
            outboundDate: FixtureFlightsDataSource.fixtureOutboundDate,
            adults: 2,
            currencyCode: "BDT",
            tripType: .oneWay
        )

        let response = try await dataSource.fetch(request)
        let decoded = try JSONDecoder.serpApi.decode(SerpApiFlightsResponse.self, from: response.data)
        let offers = FlightOfferMapper().map(decoded, request: request)

        XCTAssertGreaterThanOrEqual(offers.count, 1)
        XCTAssertTrue(offers.contains { $0.stops == 1 || $0.stops == 2 })
    }
}
