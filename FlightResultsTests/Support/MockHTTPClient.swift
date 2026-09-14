import Foundation
@testable import FlightResults

/// Test double. Mutated only by the single test driving it, never touched
/// concurrently, so `@unchecked Sendable` is safe here.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private(set) var capturedRequests: [URLRequest] = []
    var result: Result<HTTPResponse, Error> = .success(HTTPResponse(data: Data(), statusCode: 200))

    func send(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        capturedRequests.append(urlRequest)
        return try result.get()
    }
}
