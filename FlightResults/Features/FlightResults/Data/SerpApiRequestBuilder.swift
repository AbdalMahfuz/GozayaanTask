import Foundation

/// Builds the SerpApi request (spec 03 §1.2). Fixed query item order keeps the
/// cache key and tests deterministic. `api_key` is appended last and excluded
/// from `cacheableQueryItems`, which the cache key and logs are built from.
struct SerpApiRequestBuilder: Sendable {
    static let defaultBaseURL = URL(string: "https://serpapi.com/search")!

    /// SerpApi/Google Flights doesn't accept `currency=BDT` for this route:
    /// confirmed live (HTTP 400 `"Unsupported \`BDT\` for currency."`), and
    /// BDT is absent from SerpApi's own currency list. Every request asks
    /// for USD regardless of the app's business currency
    /// (`FlightSearchRequest.currencyCode`, "BDT"); `SerpApiFlightSearchService`
    /// converts the returned price with a fixed rate (D-06, NOTES.md).
    static let wireCurrencyCode = "USD"

    private let baseURL: URL
    private let apiKey: String?

    init(baseURL: URL = SerpApiRequestBuilder.defaultBaseURL, apiKey: String?) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    /// Throws `FlightSearchError.unknown` rather than trapping if the URL
    /// can't be assembled (it can't with the fixed base URL, but a crash is
    /// never the right failure for a network call).
    func buildURLRequest(for request: FlightSearchRequest) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw FlightSearchError.unknown
        }
        var items = cacheableQueryItems(for: request)
        items.append(URLQueryItem(name: "api_key", value: apiKey ?? ""))
        components.queryItems = items
        guard let url = components.url else {
            throw FlightSearchError.unknown
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        return urlRequest
    }

    /// Query items excluding `api_key` — also the cache key basis (D-09).
    func cacheableQueryItems(for request: FlightSearchRequest) -> [URLQueryItem] {
        [
            URLQueryItem(name: "engine", value: "google_flights"),
            URLQueryItem(name: "departure_id", value: request.originCode),
            URLQueryItem(name: "arrival_id", value: request.destinationCode),
            URLQueryItem(name: "outbound_date", value: formattedDate(request.outboundDate)),
            URLQueryItem(name: "type", value: request.tripType == .oneWay ? "2" : "1"),
            URLQueryItem(name: "adults", value: String(request.adults)),
            URLQueryItem(name: "currency", value: Self.wireCurrencyCode),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "gl", value: "bd")
        ]
    }

    /// `yyyy-MM-dd`, built from UTC calendar components (no `DateFormatter`
    /// needed for this, so the builder stays trivially `Sendable`).
    private func formattedDate(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return String(
            format: "%04d-%02d-%02d",
            calendar.component(.year, from: date),
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }
}
