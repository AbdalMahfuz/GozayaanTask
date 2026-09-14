import XCTest
@testable import FlightResults

final class RemoteFlightsDataSourceTests: XCTestCase {
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

    func test_missingKey_doesNotHitNetwork() async {
        let client = MockHTTPClient()
        let dataSource = RemoteFlightsDataSource(client: client, apiKey: nil)
        do {
            _ = try await dataSource.fetch(request)
            XCTFail("expected .missingAPIKey")
        } catch FlightSearchError.missingAPIKey {
            // expected
        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTAssertTrue(client.capturedRequests.isEmpty)
    }

    func test_emptyKey_doesNotHitNetwork() async {
        let client = MockHTTPClient()
        let dataSource = RemoteFlightsDataSource(client: client, apiKey: "")
        do {
            _ = try await dataSource.fetch(request)
            XCTFail("expected .missingAPIKey")
        } catch FlightSearchError.missingAPIKey {
            // expected
        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTAssertTrue(client.capturedRequests.isEmpty)
    }

    func test_presentKey_sendsRequest() async throws {
        let client = MockHTTPClient()
        client.result = .success(HTTPResponse(data: Data(), statusCode: 200))
        let dataSource = RemoteFlightsDataSource(client: client, apiKey: "secret-key")
        _ = try await dataSource.fetch(request)
        XCTAssertEqual(client.capturedRequests.count, 1)
    }
}
