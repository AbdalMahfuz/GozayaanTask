import Foundation

// Mirrors the SerpApi Google Flights response 1:1 (spec 03 §2). Strict decoding
// (D-32): only fields we use are declared; unknown fields are ignored by
// Codable's default behaviour. `Optional` is used only where SerpApi really
// leaves the field out — everything else is required, so a shape change
// fails decoding loudly instead of silently producing wrong data.

struct SerpApiFlightsResponse: Codable, Sendable {
    let searchMetadata: SearchMetadataDTO?
    let bestFlights: [FlightGroupDTO]?
    let otherFlights: [FlightGroupDTO]?
    let error: String?
}

struct SearchMetadataDTO: Codable, Sendable {
    let status: String?
}

struct FlightGroupDTO: Codable, Sendable {
    let flights: [FlightLegDTO]
    let layovers: [LayoverDTO]?
    let totalDuration: Int?
    let price: Int?
    let type: String?
    let airlineLogo: String?
}

struct FlightLegDTO: Codable, Sendable {
    let departureAirport: AirportDTO
    let arrivalAirport: AirportDTO
    let duration: Int?
    let airline: String?
    let airlineLogo: String?
    let flightNumber: String?
    let overnight: Bool?
}

struct AirportDTO: Codable, Sendable {
    let name: String?
    let id: String
    let time: String
}

struct LayoverDTO: Codable, Sendable {
    let duration: Int?
    let name: String?
    let id: String?
    let overnight: Bool?
}
