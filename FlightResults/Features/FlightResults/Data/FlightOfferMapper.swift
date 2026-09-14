import Foundation

/// Pure mapping from SerpApi's nested response shape into flat `FlightOffer`
/// domain values (spec 03 §4). No I/O beyond a DEBUG diagnostic for dropped groups.
struct FlightOfferMapper: @unchecked Sendable {
    // `DateFormatter` isn't `Sendable`, and Swift 6 rejects a `static let`
    // formatter without `nonisolated(unsafe)`, which rule R8 forbids. Created
    // once per mapper instance instead. `@unchecked Sendable` is safe here:
    // the formatter's locale/timeZone/dateFormat are fixed in `init` and
    // never mutated afterwards, and Apple documents `DateFormatter` as safe
    // for concurrent reads once configured. Logged in NOTES.md.
    private let dateFormatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter = formatter
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func map(_ response: SerpApiFlightsResponse, request: FlightSearchRequest) -> [FlightOffer] {
        let groups: [(FlightOffer.Source, FlightGroupDTO)] =
            (response.bestFlights ?? []).map { (.best, $0) } +
            (response.otherFlights ?? []).map { (.other, $0) }

        var offers: [FlightOffer] = []
        var seenIDs = Set<String>()
        var skipped = 0

        for (source, group) in groups {
            guard let offer = mapGroup(group, source: source, currencyCode: request.currencyCode) else {
                skipped += 1
                continue
            }
            guard !seenIDs.contains(offer.id) else { continue }
            seenIDs.insert(offer.id)
            offers.append(offer)
        }

        if skipped > 0 {
            Log.debug(.mapping, "Skipped \(skipped) of \(groups.count) flight groups")
        }
        return offers
    }

    func mapGroup(_ group: FlightGroupDTO, source: FlightOffer.Source, currencyCode: String) -> FlightOffer? {
        guard let firstLeg = group.flights.first, let lastLeg = group.flights.last else { return nil }
        guard let price = group.price, price > 0 else { return nil }
        guard !firstLeg.departureAirport.id.isEmpty, !lastLeg.arrivalAirport.id.isEmpty else { return nil }
        guard let departureDate = dateFormatter.date(from: firstLeg.departureAirport.time),
              let arrivalDate = dateFormatter.date(from: lastLeg.arrivalAirport.time) else { return nil }
        guard let totalDuration = resolvedDuration(for: group) else { return nil }

        let calendar = utcCalendar
        let departureComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: departureDate)
        let arrivalComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: arrivalDate)

        let departureLocal = LocalDateTime(
            year: departureComponents.year!, month: departureComponents.month!, day: departureComponents.day!,
            hour: departureComponents.hour!, minute: departureComponents.minute!
        )
        let arrivalLocal = LocalDateTime(
            year: arrivalComponents.year!, month: arrivalComponents.month!, day: arrivalComponents.day!,
            hour: arrivalComponents.hour!, minute: arrivalComponents.minute!
        )

        let departureDay = calendar.date(
            from: DateComponents(year: departureLocal.year, month: departureLocal.month, day: departureLocal.day)
        )!
        let arrivalDay = calendar.date(
            from: DateComponents(year: arrivalLocal.year, month: arrivalLocal.month, day: arrivalLocal.day)
        )!
        let dayOffset = calendar.dateComponents([.day], from: departureDay, to: arrivalDay).day ?? 0

        var airlineNames: [String] = []
        for leg in group.flights {
            guard let airline = leg.airline, !airlineNames.contains(airline) else { continue }
            airlineNames.append(airline)
        }
        if airlineNames.isEmpty { airlineNames = ["Unknown airline"] }

        let airlineLogoURL = group.airlineLogo.flatMap(URL.init(string:))
            ?? firstLeg.airlineLogo.flatMap(URL.init(string:))

        let layoverCodes = group.layovers?.compactMap(\.id) ?? group.flights.dropLast().map(\.arrivalAirport.id)

        let id = group.flights.map { leg in
            "\(leg.flightNumber ?? leg.airline ?? "?")@\(leg.departureAirport.id)@\(leg.departureAirport.time)"
        }.joined(separator: "|")

        return FlightOffer(
            id: id,
            source: source,
            airlineNames: airlineNames,
            airlineLogoURL: airlineLogoURL,
            departure: FlightEndpoint(airportCode: firstLeg.departureAirport.id, localDateTime: departureLocal),
            arrival: FlightEndpoint(airportCode: lastLeg.arrivalAirport.id, localDateTime: arrivalLocal),
            arrivalDayOffset: dayOffset,
            totalDurationMinutes: totalDuration,
            stops: group.flights.count - 1,
            layoverAirportCodes: layoverCodes,
            price: price,
            currencyCode: currencyCode
        )
    }

    private func resolvedDuration(for group: FlightGroupDTO) -> Int? {
        if let total = group.totalDuration, total > 0 { return total }
        let legDurations = group.flights.compactMap(\.duration)
        guard legDurations.count == group.flights.count else { return nil }
        let layoverDurations = group.layovers?.compactMap(\.duration) ?? []
        if let layovers = group.layovers, layoverDurations.count != layovers.count { return nil }
        let sum = legDurations.reduce(0, +) + layoverDurations.reduce(0, +)
        return sum > 0 ? sum : nil
    }
}
