import Foundation

protocol FlightsDataSource: Sendable {
    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse
}

/// Talks to SerpApi over HTTP. A missing or empty key throws before any
/// request is sent (C8) — never falls back to fixture data (D-07).
struct RemoteFlightsDataSource: FlightsDataSource {
    private let client: HTTPClient
    private let apiKey: String?
    private let requestBuilder: SerpApiRequestBuilder

    init(client: HTTPClient, apiKey: String?) {
        self.client = client
        self.apiKey = apiKey
        self.requestBuilder = SerpApiRequestBuilder(apiKey: apiKey)
    }

    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse {
        guard let apiKey, !apiKey.isEmpty else {
            throw FlightSearchError.missingAPIKey
        }
        let urlRequest = requestBuilder.buildURLRequest(for: request)
        if let url = urlRequest.url {
            Log.debug(.network, "GET \(Log.redact(url: url))")
        }
        return try await client.send(urlRequest)
    }
}
