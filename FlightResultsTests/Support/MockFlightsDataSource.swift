import Foundation
@testable import FlightResults

/// Test double. Mutated only by the single test driving it.
final class MockFlightsDataSource: FlightsDataSource, @unchecked Sendable {
    var result: Result<HTTPResponse, Error> = .success(HTTPResponse(data: Data(), statusCode: 200))
    private(set) var fetchCount = 0

    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse {
        fetchCount += 1
        return try result.get()
    }
}
