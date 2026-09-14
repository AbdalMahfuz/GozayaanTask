import Foundation

#if DEBUG
/// Forces a screen state for review/walkthrough (spec 02 §5, D-08). Only
/// reachable through `-FRForceState`, read exclusively in `AppEnvironment`.
struct StubFlightSearchService: FlightSearchService {
    enum Mode: String {
        case loading, empty, error
    }

    let mode: Mode

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        switch mode {
        case .loading:
            // Never resolves; only cancellation (e.g. leaving the screen) ends it.
            try await Task.sleep(for: .seconds(1_000_000))
            return []
        case .empty:
            try await Task.sleep(for: .seconds(1))
            return []
        case .error:
            try await Task.sleep(for: .seconds(1))
            throw FlightSearchError.offline
        }
    }
}
#endif
