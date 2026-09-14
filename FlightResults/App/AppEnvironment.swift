import Foundation

/// Composition root: the only place that reads process info, launch arguments
/// and configuration to decide which implementations the app runs with
/// (spec 04 §4). `#if DEBUG` and launch-argument reads live only here (A8).
@MainActor
struct AppEnvironment {
    let config: AppConfig
    let flightSearchService: FlightSearchService
    let searchRequest: FlightSearchRequest
    let dummyContent: DummyContentProvider
    let imageLoader: ImageLoading

    static func make(
        launchArguments: [String] = ProcessInfo.processInfo.arguments,
        config: AppConfig = .fromBundle(),
        now: Date = .now
    ) -> AppEnvironment {
        let usesFixture = isFixtureMode(launchArguments)
        let outboundDate = usesFixture
            ? FixtureFlightsDataSource.fixtureOutboundDate
            : defaultOutboundDate(from: now)

        let request = FlightSearchRequest(
            originCode: "DAC",
            destinationCode: "JFK",
            originCity: "Dhaka",
            destinationCity: "New York",
            outboundDate: outboundDate,
            adults: 2,
            currencyCode: "BDT",
            tripType: .oneWay
        )

        return AppEnvironment(
            config: config,
            flightSearchService: makeService(launchArguments: launchArguments, config: config, usesFixture: usesFixture),
            searchRequest: request,
            dummyContent: .make(searchDate: outboundDate),
            imageLoader: ImageLoader()
        )
    }

    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private static func defaultOutboundDate(from now: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(byAdding: .day, value: 30, to: now) ?? now
    }

    private static func isFixtureMode(_ launchArguments: [String]) -> Bool {
        #if DEBUG
        argumentValue(named: "-FRDataSource", in: launchArguments) == "fixture"
        #else
        false
        #endif
    }

    private static func makeService(
        launchArguments: [String],
        config: AppConfig,
        usesFixture: Bool
    ) -> FlightSearchService {
        #if DEBUG
        if let modeRaw = argumentValue(named: "-FRForceState", in: launchArguments),
           let mode = StubFlightSearchService.Mode(rawValue: modeRaw) {
            return StubFlightSearchService(mode: mode)
        }
        if usesFixture {
            return SerpApiFlightSearchService(dataSource: FixtureFlightsDataSource())
        }
        let remote = RemoteFlightsDataSource(client: URLSessionHTTPClient(), apiKey: config.serpApiKey)
        let cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SerpApiResponseCache", isDirectory: true)
        let cached = CachedFlightsDataSource(wrapping: remote, directory: cacheDirectory, ttl: 6 * 3600)
        return SerpApiFlightSearchService(dataSource: cached)
        #else
        let remote = RemoteFlightsDataSource(client: URLSessionHTTPClient(), apiKey: config.serpApiKey)
        return SerpApiFlightSearchService(dataSource: remote)
        #endif
    }

    #if DEBUG
    private static func argumentValue(named name: String, in launchArguments: [String]) -> String? {
        guard let index = launchArguments.firstIndex(of: name), index + 1 < launchArguments.count else {
            return nil
        }
        return launchArguments[index + 1]
    }
    #endif
}
