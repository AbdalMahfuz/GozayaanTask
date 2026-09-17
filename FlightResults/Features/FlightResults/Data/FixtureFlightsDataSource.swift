import Foundation

/// Serves a bundled, real SerpApi response with a simulated delay so the
/// loading state can be demoed with no key (D-08, scheme `FlightResults (Fixture)`).
struct FixtureFlightsDataSource: FlightsDataSource {
    private let bundle: Bundle
    private let name: String
    private let delay: Duration

    init(bundle: Bundle = .main, name: String = "serpapi_dac_jfk_oneway", delay: Duration = .seconds(1.5)) {
        self.bundle = bundle
        self.name = name
        self.delay = delay
    }

    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse {
        try await Task.sleep(for: delay)
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return HTTPResponse(data: Data("{}".utf8), statusCode: 200)
        }
        return HTTPResponse(data: data, statusCode: 200)
    }
}

extension FixtureFlightsDataSource {
    /// The outbound date baked into `serpapi_dac_jfk_oneway.json`, so fixture
    /// mode's header stays consistent with the data actually shown (D-04).
    static let fixtureOutboundDate = Date(timeIntervalSince1970: 1_791_936_000) // 2026-10-14T00:00:00Z
}
