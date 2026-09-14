import Foundation

/// HTTP status / body → result mapping table lives in spec 03 §4.8.
struct SerpApiFlightSearchService: FlightSearchService {
    private let dataSource: FlightsDataSource
    private let mapper: FlightOfferMapper

    init(dataSource: FlightsDataSource, mapper: FlightOfferMapper = .init()) {
        self.dataSource = dataSource
        self.mapper = mapper
    }

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        // `JSONDecoder` isn't `Sendable`, so a fresh one is created here
        // rather than stored (spec 04 §3.4).
        let decoder = JSONDecoder.serpApi
        let response = try await fetchResponse(for: request)

        switch response.statusCode {
        case 401, 403:
            throw FlightSearchError.unauthorized
        case 429:
            throw FlightSearchError.rateLimited
        case 200..<300:
            return try decodeSuccess(response.data, request: request, decoder: decoder)
        default:
            throw Self.classifyErrorBody(response.data, status: response.statusCode, decoder: decoder)
        }
    }

    private func fetchResponse(for request: FlightSearchRequest) async throws -> HTTPResponse {
        do {
            return try await dataSource.fetch(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as FlightSearchError {
            throw error
        } catch let urlError as URLError {
            if urlError.code == .cancelled { throw CancellationError() }
            throw Self.classify(urlError)
        } catch {
            throw FlightSearchError.unknown
        }
    }

    private func decodeSuccess(
        _ data: Data,
        request: FlightSearchRequest,
        decoder: JSONDecoder
    ) throws -> [FlightOffer] {
        let decoded: SerpApiFlightsResponse
        do {
            decoded = try decoder.decode(SerpApiFlightsResponse.self, from: data)
        } catch {
            throw FlightSearchError.decoding
        }

        if let message = decoded.error {
            if SerpApiErrorClassifier.isNoResultsMessage(message) {
                return []
            }
            throw FlightSearchError.server(status: 200, message: message)
        }
        if decoded.searchMetadata?.status == "Error" {
            throw FlightSearchError.server(status: 200, message: nil)
        }
        return Self.convertToDisplayCurrency(mapper.map(decoded, request: request), request: request)
    }

    /// SerpApi always returns USD (`SerpApiRequestBuilder.wireCurrencyCode`);
    /// converts each offer's price into the app's business currency
    /// (`request.currencyCode`, "BDT") with a fixed, hand-set rate. Not a
    /// live FX rate — a known limitation (D-06, NOTES.md).
    private static let fixedUSDToBDTRate = 122.0

    private static func convertToDisplayCurrency(
        _ offers: [FlightOffer],
        request: FlightSearchRequest
    ) -> [FlightOffer] {
        guard request.currencyCode != SerpApiRequestBuilder.wireCurrencyCode else { return offers }
        return offers.map { offer in
            FlightOffer(
                id: offer.id,
                source: offer.source,
                airlineNames: offer.airlineNames,
                airlineLogoURL: offer.airlineLogoURL,
                departure: offer.departure,
                arrival: offer.arrival,
                arrivalDayOffset: offer.arrivalDayOffset,
                totalDurationMinutes: offer.totalDurationMinutes,
                stops: offer.stops,
                layoverAirportCodes: offer.layoverAirportCodes,
                price: Int((Double(offer.price) * fixedUSDToBDTRate).rounded()),
                currencyCode: offer.currencyCode
            )
        }
    }

    private static func classifyErrorBody(_ data: Data, status: Int, decoder: JSONDecoder) -> FlightSearchError {
        guard let decoded = try? decoder.decode(SerpApiFlightsResponse.self, from: data),
              let message = decoded.error else {
            return .server(status: status, message: nil)
        }
        if SerpApiErrorClassifier.isRateLimitMessage(message) {
            return .rateLimited
        }
        return .server(status: status, message: message)
    }

    private static func classify(_ urlError: URLError) -> FlightSearchError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .unknown
        }
    }
}
