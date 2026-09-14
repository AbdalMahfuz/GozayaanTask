import Foundation

enum FlightSearchError: Error, Equatable, Sendable {
    case offline
    case timeout
    case missingAPIKey
    case unauthorized
    case rateLimited
    case server(status: Int, message: String?)
    case decoding
    case unknown
}
