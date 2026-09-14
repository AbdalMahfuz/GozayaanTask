import Foundation

struct FlightSearchRequest: Codable, Hashable, Sendable {
    let originCode: String
    let destinationCode: String
    let originCity: String
    let destinationCity: String
    let outboundDate: Date
    let adults: Int
    let currencyCode: String
    let tripType: TripType
}

enum TripType: String, Codable, Sendable {
    case oneWay = "One Way"
}
