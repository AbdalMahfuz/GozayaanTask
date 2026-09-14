import Foundation

protocol FlightSearchService: Sendable {
    /// Throws `FlightSearchError` or `CancellationError`.
    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer]
}
