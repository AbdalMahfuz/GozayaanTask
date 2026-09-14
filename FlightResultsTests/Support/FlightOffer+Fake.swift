import Foundation
@testable import FlightResults

extension FlightOffer {
    static func fake(
        id: String = "BG 147@DAC@2026-02-15 12:30",
        source: Source = .best,
        airlineNames: [String] = ["Biman Bangladesh Airlines"],
        airlineLogoURL: URL? = URL(string: "https://example.com/logos/biman.png"),
        departureCode: String = "DAC",
        departure: LocalDateTime = LocalDateTime(year: 2026, month: 2, day: 15, hour: 12, minute: 30),
        arrivalCode: String = "BKK",
        arrival: LocalDateTime = LocalDateTime(year: 2026, month: 2, day: 15, hour: 16, minute: 50),
        arrivalDayOffset: Int = 0,
        totalDurationMinutes: Int = 280,
        stops: Int = 0,
        layoverAirportCodes: [String] = [],
        price: Int = 37400,
        currencyCode: String = "BDT"
    ) -> FlightOffer {
        FlightOffer(
            id: id,
            source: source,
            airlineNames: airlineNames,
            airlineLogoURL: airlineLogoURL,
            departure: FlightEndpoint(airportCode: departureCode, localDateTime: departure),
            arrival: FlightEndpoint(airportCode: arrivalCode, localDateTime: arrival),
            arrivalDayOffset: arrivalDayOffset,
            totalDurationMinutes: totalDurationMinutes,
            stops: stops,
            layoverAirportCodes: layoverAirportCodes,
            price: price,
            currencyCode: currencyCode
        )
    }
}
