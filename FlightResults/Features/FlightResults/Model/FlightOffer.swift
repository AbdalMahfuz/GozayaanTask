import Foundation

struct FlightOffer: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let source: Source
    let airlineNames: [String]
    let airlineLogoURL: URL?
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let arrivalDayOffset: Int
    let totalDurationMinutes: Int
    let stops: Int
    let layoverAirportCodes: [String]
    let price: Int
    let currencyCode: String

    enum Source: String, Codable, Sendable {
        case best, other
    }
}

struct FlightEndpoint: Codable, Hashable, Sendable {
    let airportCode: String
    let localDateTime: LocalDateTime
}

struct LocalDateTime: Codable, Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int

    static func < (lhs: LocalDateTime, rhs: LocalDateTime) -> Bool {
        (lhs.year, lhs.month, lhs.day, lhs.hour, lhs.minute)
            < (rhs.year, rhs.month, rhs.day, rhs.hour, rhs.minute)
    }
}
