import XCTest
@testable import FlightResults

final class CachedFlightsDataSourceTests: XCTestCase {
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

    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CachedFlightsDataSourceTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func makeCache(
        wrapping inner: MockFlightsDataSource,
        ttl: TimeInterval = 3600,
        now: @escaping @Sendable () -> Date
    ) -> CachedFlightsDataSource {
        CachedFlightsDataSource(wrapping: inner, directory: tempDirectory, ttl: ttl, now: now)
    }

    func test_secondIdenticalRequestWithinTTL_doesNotCallInnerSource() async throws {
        let inner = MockFlightsDataSource()
        inner.result = .success(HTTPResponse(data: Data("payload".utf8), statusCode: 200))
        let cache = makeCache(wrapping: inner, now: { Date(timeIntervalSince1970: 0) })

        _ = try await cache.fetch(request)
        _ = try await cache.fetch(request)

        XCTAssertEqual(inner.fetchCount, 1)
    }

    func test_afterTTL_callsInnerSourceAgain() async throws {
        let inner = MockFlightsDataSource()
        inner.result = .success(HTTPResponse(data: Data("payload".utf8), statusCode: 200))
        let clock = TestClock(Date(timeIntervalSince1970: 0))
        let cache = makeCache(wrapping: inner, ttl: 60, now: { clock.date })

        _ = try await cache.fetch(request)
        clock.date = clock.date.addingTimeInterval(120)
        _ = try await cache.fetch(request)

        XCTAssertEqual(inner.fetchCount, 2)
    }

    func test_non2xxResponse_isNotCached() async throws {
        let inner = MockFlightsDataSource()
        inner.result = .success(HTTPResponse(data: Data("error".utf8), statusCode: 500))
        let cache = makeCache(wrapping: inner, now: { Date(timeIntervalSince1970: 0) })

        _ = try await cache.fetch(request)
        _ = try await cache.fetch(request)

        XCTAssertEqual(inner.fetchCount, 2)
    }

    func test_cacheKey_excludesApiKey() async throws {
        // The cache key is built from `cacheableQueryItems`, which never
        // includes `api_key` (SerpApiRequestBuilderTests covers that
        // directly). Here: a second cache instance, wrapping a data source
        // that would stand in for a differently-configured API key, still
        // hits the same cache file for the same request.
        let innerA = MockFlightsDataSource()
        innerA.result = .success(HTTPResponse(data: Data("payload".utf8), statusCode: 200))
        let cacheA = makeCache(wrapping: innerA, now: { Date(timeIntervalSince1970: 0) })
        _ = try await cacheA.fetch(request)

        let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(contents.count, 1)

        let innerB = MockFlightsDataSource()
        let cacheB = makeCache(wrapping: innerB, now: { Date(timeIntervalSince1970: 0) })
        _ = try await cacheB.fetch(request)

        XCTAssertEqual(innerB.fetchCount, 0)
    }
}

/// A `var` can't be captured by an `@Sendable` closure directly (Swift 6
/// rejects mutable captures in concurrently-callable closures). This boxes
/// the mutable date in a class instead — the closure captures the box (a
/// `let`), and only the single test driving it ever mutates `date`.
private final class TestClock: @unchecked Sendable {
    var date: Date
    init(_ date: Date) { self.date = date }
}
