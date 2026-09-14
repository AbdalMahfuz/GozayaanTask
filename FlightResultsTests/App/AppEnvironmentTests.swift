import XCTest
@testable import FlightResults

@MainActor
final class AppEnvironmentTests: XCTestCase {
    func test_forceStateLoading_usesStubService() {
        let environment = AppEnvironment.make(launchArguments: ["/path", "-FRForceState", "loading"])
        XCTAssertTrue(environment.flightSearchService is StubFlightSearchService)
    }

    func test_forceStateError_usesStubServiceInErrorMode() async throws {
        let environment = AppEnvironment.make(launchArguments: ["/path", "-FRForceState", "error"])
        do {
            _ = try await environment.flightSearchService.searchFlights(environment.searchRequest)
            XCTFail("expected an error")
        } catch FlightSearchError.offline {
            // expected
        }
    }

    func test_fixtureDataSource_usesFixtureOutboundDate() {
        let environment = AppEnvironment.make(launchArguments: ["/path", "-FRDataSource", "fixture"])
        XCTAssertEqual(environment.searchRequest.outboundDate, FixtureFlightsDataSource.fixtureOutboundDate)
    }

    func test_default_usesDatePlus30Days() {
        let now = Date(timeIntervalSince1970: 1_760_400_000) // 2025-10-14T00:00:00Z
        let environment = AppEnvironment.make(launchArguments: ["/path"], now: now)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let expected = calendar.date(byAdding: .day, value: 30, to: now)
        XCTAssertEqual(environment.searchRequest.outboundDate, expected)
    }
}
