import XCTest
@testable import FlightResults

final class DecodingTests: XCTestCase {
    private func decode(_ fixture: String) throws -> SerpApiFlightsResponse {
        try JSONDecoder.serpApi.decode(SerpApiFlightsResponse.self, from: FixtureLoader.data(named: fixture))
    }

    func test_validResponse_decodes() throws {
        let response = try decode("nonstop")
        XCTAssertEqual(response.bestFlights?.count, 1)
        XCTAssertEqual(response.bestFlights?.first?.price, 37400)
    }

    func test_missingRequiredKey_throwsDecoding() {
        XCTAssertThrowsError(try decode("missing_required_key")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_typeMismatch_throwsDecoding() {
        XCTAssertThrowsError(try decode("type_mismatch")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_malformedJson_throwsDecoding() {
        XCTAssertThrowsError(try decode("malformed")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_domainModels_roundTrip() throws {
        let offer = FlightOffer.fake(id: "BG 147@DAC@2026-02-15 12:30")
        let encoded = try JSONEncoder().encode(offer)
        let decoded = try JSONDecoder().decode(FlightOffer.self, from: encoded)
        XCTAssertEqual(offer, decoded)

        let request = FlightSearchRequest(
            originCode: "DAC",
            destinationCode: "JFK",
            originCity: "Dhaka",
            destinationCity: "New York",
            outboundDate: Date(timeIntervalSince1970: 1_760_400_000),
            adults: 2,
            currencyCode: "BDT",
            tripType: .oneWay
        )
        let encodedRequest = try JSONEncoder().encode(request)
        let decodedRequest = try JSONDecoder().decode(FlightSearchRequest.self, from: encodedRequest)
        XCTAssertEqual(request, decodedRequest)
    }
}
