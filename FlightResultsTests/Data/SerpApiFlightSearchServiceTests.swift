import XCTest
@testable import FlightResults

final class SerpApiFlightSearchServiceTests: XCTestCase {
    private let request = FlightSearchRequest(
        originCode: "DAC",
        destinationCode: "JFK",
        originCity: "Dhaka",
        destinationCity: "New York",
        outboundDate: Date(timeIntervalSince1970: 1_760_400_000),
        adults: 2,
        currencyCode: "USD", // matches the wire currency, so no conversion applies here
        tripType: .oneWay
    )

    private func makeService(_ dataSource: MockFlightsDataSource) -> SerpApiFlightSearchService {
        SerpApiFlightSearchService(dataSource: dataSource)
    }

    private func response(_ fixture: String, status: Int = 200) -> HTTPResponse {
        HTTPResponse(data: FixtureLoader.data(named: fixture), statusCode: status)
    }

    func test_success() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("nonstop"))
        let offers = try await makeService(dataSource).searchFlights(request)
        XCTAssertEqual(offers.count, 1)
        XCTAssertEqual(offers.first?.price, 37400)
    }

    func test_success_convertsPriceToBusinessCurrency() async throws {
        let bdtRequest = FlightSearchRequest(
            originCode: "DAC",
            destinationCode: "JFK",
            originCity: "Dhaka",
            destinationCity: "New York",
            outboundDate: Date(timeIntervalSince1970: 1_760_400_000),
            adults: 2,
            currencyCode: "BDT",
            tripType: .oneWay
        )
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("nonstop"))
        let offers = try await makeService(dataSource).searchFlights(bdtRequest)
        XCTAssertEqual(offers.first?.price, 4_562_800) // 37400 * 122 (D-06 fixed rate)
        XCTAssertEqual(offers.first?.currencyCode, "BDT")
    }

    func test_noResultsError_returnsEmpty() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("no_results_error"))
        let offers = try await makeService(dataSource).searchFlights(request)
        XCTAssertEqual(offers, [])
    }

    func test_emptyArrays_returnsEmpty() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("empty_arrays"))
        let offers = try await makeService(dataSource).searchFlights(request)
        XCTAssertEqual(offers, [])
    }

    func test_otherApiError_throwsServer() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("api_error_200"))
        do {
            _ = try await makeService(dataSource).searchFlights(request)
            XCTFail("expected .server")
        } catch FlightSearchError.server(let status, let message) {
            XCTAssertEqual(status, 200)
            XCTAssertEqual(message, "Invalid departure_id")
        }
    }

    func test_httpStatus_mapping() async throws {
        let cases: [(Int, FlightSearchError)] = [
            (401, .unauthorized),
            (403, .unauthorized),
            (429, .rateLimited),
            (500, .server(status: 500, message: nil))
        ]
        for (status, expected) in cases {
            let dataSource = MockFlightsDataSource()
            dataSource.result = .success(HTTPResponse(data: Data(), statusCode: status))
            do {
                _ = try await makeService(dataSource).searchFlights(request)
                XCTFail("expected \(expected) for status \(status)")
            } catch let error as FlightSearchError {
                XCTAssertEqual(error, expected, "for status \(status)")
            }
        }
    }

    func test_malformedJson_throwsDecoding() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .success(response("malformed"))
        do {
            _ = try await makeService(dataSource).searchFlights(request)
            XCTFail("expected .decoding")
        } catch FlightSearchError.decoding {
            // expected
        }
    }

    func test_urlError_mapping() async throws {
        let cases: [(URLError.Code, FlightSearchError)] = [
            (.notConnectedToInternet, .offline),
            (.timedOut, .timeout),
            (.networkConnectionLost, .offline)
        ]
        for (code, expected) in cases {
            let dataSource = MockFlightsDataSource()
            dataSource.result = .failure(URLError(code))
            do {
                _ = try await makeService(dataSource).searchFlights(request)
                XCTFail("expected \(expected) for \(code)")
            } catch let error as FlightSearchError {
                XCTAssertEqual(error, expected, "for \(code)")
            }
        }
    }

    func test_cancelledUrlError_throwsCancellationError() async throws {
        let dataSource = MockFlightsDataSource()
        dataSource.result = .failure(URLError(.cancelled))
        do {
            _ = try await makeService(dataSource).searchFlights(request)
            XCTFail("expected CancellationError")
        } catch is CancellationError {
            // expected
        }
    }
}
