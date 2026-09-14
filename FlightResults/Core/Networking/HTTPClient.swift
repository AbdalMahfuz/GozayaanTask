import Foundation

protocol HTTPClient: Sendable {
    func send(_ urlRequest: URLRequest) async throws -> HTTPResponse
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(_ urlRequest: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return HTTPResponse(data: data, statusCode: httpResponse.statusCode)
    }
}
