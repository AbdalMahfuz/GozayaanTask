import CryptoKit
import Foundation

/// DEBUG disk cache in front of another data source (D-08, D-09). Caches raw
/// `Data`, not decoded models, so mapping changes take effect immediately.
/// The cache key is the request's query items excluding `api_key`.
struct CachedFlightsDataSource: FlightsDataSource {
    private let wrapped: FlightsDataSource
    private let directory: URL
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let requestBuilder = SerpApiRequestBuilder(apiKey: nil)

    init(
        wrapping wrapped: FlightsDataSource,
        directory: URL,
        ttl: TimeInterval,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.wrapped = wrapped
        self.directory = directory
        self.ttl = ttl
        self.now = now
    }

    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse {
        let fileURL = directory.appendingPathComponent(cacheKey(for: request)).appendingPathExtension("json")

        if let cached = readEntry(at: fileURL), now().timeIntervalSince(cached.storedAt) < ttl {
            Log.debug(.network, "cache hit")
            return HTTPResponse(data: cached.data, statusCode: 200)
        }

        let response = try await wrapped.fetch(request)
        if (200..<300).contains(response.statusCode) {
            writeEntry(CacheEntry(data: response.data, storedAt: now()), to: fileURL)
        }
        return response
    }

    private func cacheKey(for request: FlightSearchRequest) -> String {
        let items = requestBuilder.cacheableQueryItems(for: request)
        let raw = items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func readEntry(at url: URL) -> CacheEntry? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CacheEntry.self, from: raw)
    }

    private func writeEntry(_ entry: CacheEntry, to url: URL) {
        guard let encoded = try? JSONEncoder().encode(entry) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? encoded.write(to: url, options: .atomic)
    }

    private struct CacheEntry: Codable {
        let data: Data
        let storedAt: Date
    }
}
