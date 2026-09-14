import XCTest
@testable import FlightResults

final class SerpApiRequestBuilderTests: XCTestCase {
    private let request = FlightSearchRequest(
        originCode: "DAC",
        destinationCode: "JFK",
        originCity: "Dhaka",
        destinationCity: "New York",
        outboundDate: Date(timeIntervalSince1970: 1_760_400_000), // 2025-10-14T00:00:00Z
        adults: 2,
        currencyCode: "BDT",
        tripType: .oneWay
    )

    func test_buildsExpectedQueryItems() throws {
        let builder = SerpApiRequestBuilder(apiKey: "secret-key")
        let urlRequest = builder.buildURLRequest(for: request)
        let url = try XCTUnwrap(urlRequest.url)
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertEqual(items.map(\.name), [
            "engine", "departure_id", "arrival_id", "outbound_date",
            "type", "adults", "currency", "hl", "gl", "api_key"
        ])
        XCTAssertEqual(items.first { $0.name == "engine" }?.value, "google_flights")
        XCTAssertEqual(items.first { $0.name == "departure_id" }?.value, "DAC")
        XCTAssertEqual(items.first { $0.name == "arrival_id" }?.value, "JFK")
        XCTAssertEqual(items.first { $0.name == "type" }?.value, "2")
        XCTAssertEqual(items.first { $0.name == "adults" }?.value, "2")
        // Wire currency is always USD, regardless of the request's business
        // currency ("BDT") — SerpApi rejects BDT (D-06).
        XCTAssertEqual(items.first { $0.name == "currency" }?.value, "USD")
        XCTAssertEqual(items.first { $0.name == "hl" }?.value, "en")
        XCTAssertEqual(items.first { $0.name == "gl" }?.value, "bd")
        XCTAssertEqual(items.first { $0.name == "api_key" }?.value, "secret-key")
    }

    func test_outboundDate_isTimeZoneIndependent() throws {
        let builder = SerpApiRequestBuilder(apiKey: "secret-key")
        let originalTimeZone = NSTimeZone.default
        defer { NSTimeZone.default = originalTimeZone }

        var dates: Set<String> = []
        for identifier in ["Pacific/Kiritimati", "Pacific/Pago_Pago"] {
            NSTimeZone.default = try XCTUnwrap(TimeZone(identifier: identifier))
            let url = try XCTUnwrap(builder.buildURLRequest(for: request).url)
            let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            dates.insert(try XCTUnwrap(items.first { $0.name == "outbound_date" }?.value))
        }

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(dates.first, "2025-10-14")
    }

    func test_cacheableQueryItems_excludesApiKey() {
        let builder = SerpApiRequestBuilder(apiKey: "secret-key")
        let items = builder.cacheableQueryItems(for: request)
        XCTAssertFalse(items.contains { $0.name == "api_key" })
    }
}
