import Foundation

/// Screen state, the search call, sort logic and ViewData formatting
/// (spec 04 §3.2). Imports Foundation only — never UIKit, SafariServices, or
/// the Coordinator's concrete type.
@MainActor
final class FlightResultsViewModel {
    private(set) var state: FlightResultsState = .loading {
        didSet { onStateChange?(state) }
    }
    private(set) var sortOption: SortOption = .cheapest
    let header: RouteHeaderViewData
    let dateFares: [DateFareViewData]
    let promotions: [PromotionViewData]
    var onStateChange: ((FlightResultsState) -> Void)?
    var onSortOptionChange: ((SortOption) -> Void)?

    weak var coordinatorDelegate: FlightResultsCoordinatorDelegate?

    private let request: FlightSearchRequest
    private let service: FlightSearchService
    private let formatters: FlightFormatters
    private let promotionsByID: [String: Promotion]

    private var offers: [FlightOffer] = []
    private var isLoading = false
    private var generation = 0

    // Deinit isn't main-actor-isolated, so the running task is kept in this
    // plain `nonisolated` box instead of a `@MainActor` stored property, so
    // `deinit` can still cancel it (spec 04 §3.2).
    private nonisolated let taskBox = CancellableTaskBox()

    init(
        request: FlightSearchRequest,
        service: FlightSearchService,
        promotions: [Promotion],
        dateFares: [DateFare],
        formatters: FlightFormatters = .init()
    ) {
        self.request = request
        self.service = service
        self.formatters = formatters
        self.header = Self.makeHeader(request: request, formatters: formatters)
        self.dateFares = dateFares.map { Self.makeDateFare($0, currencyCode: request.currencyCode, formatters: formatters) }
        self.promotions = promotions.map { Self.makePromotion($0) }
        self.promotionsByID = Dictionary(uniqueKeysWithValues: promotions.map { ($0.id, $0) })
    }

    deinit {
        taskBox.cancel()
    }

    // MARK: - Intents

    func start() {
        guard let pending = beginLoad() else { return }
        // The task holds only the service and request while it waits — never
        // `self`. Holding `self` across the `await` would keep the ViewModel
        // alive until the request finished, so `deinit` could never cancel it.
        let task = Task { [weak self] in
            let outcome = await Self.search(pending)
            self?.finishLoad(outcome, generation: pending.generation)
        }
        taskBox.set(task)
    }

    func retry() {
        start()
    }

    /// Same flow as `start()`, awaited by the caller. Used by tests.
    func load() async {
        guard let pending = beginLoad() else { return }
        let outcome = await Self.search(pending)
        finishLoad(outcome, generation: pending.generation)
    }

    private struct PendingLoad: Sendable {
        let generation: Int
        let service: FlightSearchService
        let request: FlightSearchRequest
    }

    private func beginLoad() -> PendingLoad? {
        guard !isLoading else { return nil }
        isLoading = true
        generation += 1
        state = .loading
        return PendingLoad(generation: generation, service: service, request: request)
    }

    private nonisolated static func search(_ pending: PendingLoad) async -> Result<[FlightOffer], Error> {
        do {
            return .success(try await pending.service.searchFlights(pending.request))
        } catch {
            return .failure(error)
        }
    }

    private func finishLoad(_ outcome: Result<[FlightOffer], Error>, generation loadGeneration: Int) {
        isLoading = false
        guard loadGeneration == generation, !Task.isCancelled else { return }

        switch outcome {
        case .success(let result):
            offers = result
            if result.isEmpty {
                state = .empty(Self.makeEmptyData(request: request, formatters: formatters))
            } else {
                state = .success(makeCards(FlightOfferSorter.sort(result, by: sortOption)))
            }
        case .failure(let error):
            guard !(error is CancellationError) else { return }
            let flightError = (error as? FlightSearchError) ?? .unknown
            state = .error(Self.makeErrorData(flightError))
        }
    }

    func selectSort(_ option: SortOption) {
        guard option != sortOption else { return }
        sortOption = option
        onSortOptionChange?(option)
        if case .success = state {
            state = .success(makeCards(FlightOfferSorter.sort(offers, by: option)))
        }
    }

    func didSelectFlight(id: String) {
        guard let offer = offers.first(where: { $0.id == id }) else { return }
        coordinatorDelegate?.didSelectFlight(offer)
    }

    func didSelectPromotion(id: String) {
        guard let promotion = promotionsByID[id] else { return }
        coordinatorDelegate?.didSelectPromotion(promotion)
    }

    // MARK: - ViewData building

    private func makeCards(_ offers: [FlightOffer]) -> [FlightCardViewData] {
        offers.map { offer in
            let stopsText = formatters.stops.label(for: offer.stops)
            let durationText = formatters.duration.string(from: offer.totalDurationMinutes)
            let airlineText = offer.airlineNames.joined(separator: " + ")
            return FlightCardViewData(
                id: offer.id,
                airlineText: airlineText,
                airlineLogoURL: offer.airlineLogoURL,
                departureTime: formatters.time.string(from: offer.departure.localDateTime),
                departureCode: offer.departure.airportCode,
                arrivalTime: formatters.time.string(from: offer.arrival.localDateTime),
                arrivalDayOffsetText: formatters.dayOffset.string(from: offer.arrivalDayOffset),
                arrivalCode: offer.arrival.airportCode,
                durationText: durationText,
                stopsText: stopsText,
                stopDotCount: formatters.stops.dotCount(for: offer.stops),
                currencyCode: offer.currencyCode,
                priceText: formatters.price.amount(offer.price),
                accessibilityLabel: Self.makeAccessibilityLabel(offer: offer, formatters: formatters)
            )
        }
    }

    private static func makeHeader(request: FlightSearchRequest, formatters: FlightFormatters) -> RouteHeaderViewData {
        RouteHeaderViewData(
            title: "\(request.originCity) - \(request.destinationCity)",
            dateText: formatters.headerDate.string(from: request.outboundDate),
            passengerText: formatters.passenger.string(from: request.adults),
            tripTypeText: request.tripType.rawValue
        )
    }

    private static func makeDateFare(_ fare: DateFare, currencyCode: String, formatters: FlightFormatters) -> DateFareViewData {
        DateFareViewData(
            dateText: formatters.chipDate.string(from: fare.date),
            priceText: formatters.price.full(fare.price, currencyCode: currencyCode),
            isSelected: fare.isSelected
        )
    }

    private static func makePromotion(_ promotion: Promotion) -> PromotionViewData {
        PromotionViewData(
            id: promotion.id,
            imageName: promotion.imageName,
            title: promotion.title,
            linkText: "Learn more"
        )
    }

    private static func makeEmptyData(request: FlightSearchRequest, formatters: FlightFormatters) -> EmptyStateViewData {
        let dateText = formatters.headerDate.string(from: request.outboundDate)
        return EmptyStateViewData(
            title: "No flights found",
            message: "We couldn\u{2019}t find any flights from \(request.originCode) to \(request.destinationCode) on \(dateText). Try a different date."
        )
    }

    private static func makeErrorData(_ error: FlightSearchError) -> ErrorStateViewData {
        switch error {
        case .offline:
            return ErrorStateViewData(
                kind: .connectivity,
                title: "No internet connection",
                message: "Check your connection and try again.",
                debugDetail: debugDetail(for: error)
            )
        case .timeout:
            return ErrorStateViewData(
                kind: .connectivity,
                title: "This is taking too long",
                message: "The search timed out. Please try again.",
                debugDetail: debugDetail(for: error)
            )
        case .missingAPIKey:
            return ErrorStateViewData(
                kind: .general,
                title: "Search unavailable",
                message: "Flight search isn\u{2019}t configured.",
                debugDetail: debugDetail(for: error)
            )
        case .unauthorized:
            return ErrorStateViewData(
                kind: .general,
                title: "Search unavailable",
                message: "We couldn\u{2019}t connect to flight search. Please try again later.",
                debugDetail: debugDetail(for: error)
            )
        case .rateLimited:
            return ErrorStateViewData(
                kind: .general,
                title: "Too many searches",
                message: "Please wait a moment and try again.",
                debugDetail: debugDetail(for: error)
            )
        case .server, .decoding, .unknown:
            return ErrorStateViewData(
                kind: .general,
                title: "Something went wrong",
                message: "We couldn\u{2019}t load flights right now. Please try again.",
                debugDetail: debugDetail(for: error)
            )
        }
    }

    private static func debugDetail(for error: FlightSearchError) -> String? {
        #if DEBUG
        switch error {
        case .offline:
            return "URLError: offline"
        case .timeout:
            return "URLError: timed out"
        case .missingAPIKey:
            return "Add SERPAPI_API_KEY to Config/Secrets.xcconfig"
        case .unauthorized:
            return "HTTP 401/403: unauthorized"
        case .rateLimited:
            return "HTTP 429: rate limited"
        case .server(let status, let message):
            return "HTTP \(status): \(message ?? "no message")"
        case .decoding:
            return "Decoding error"
        case .unknown:
            return "Unknown error"
        }
        #else
        return nil
        #endif
    }

    private static func makeAccessibilityLabel(offer: FlightOffer, formatters: FlightFormatters) -> String {
        let airlineText = offer.airlineNames.joined(separator: " + ")
        let departureTime = formatters.time.string(from: offer.departure.localDateTime)
        let arrivalTime = formatters.time.string(from: offer.arrival.localDateTime)
        let nextDaySuffix = offer.arrivalDayOffset != 0 ? ", next day" : ""

        let hours = offer.totalDurationMinutes / 60
        let minutes = offer.totalDurationMinutes % 60
        let durationPhrase: String
        switch (hours, minutes) {
        case (0, let m):
            durationPhrase = "\(m) minutes"
        case (let h, 0):
            durationPhrase = "\(h) hours"
        default:
            durationPhrase = "\(hours) hours \(minutes) minutes"
        }

        let stopsPhrase = offer.stops == 0 ? "Non-Stop" : "\(offer.stops) stop\(offer.stops == 1 ? "" : "s")"
        let priceText = formatters.price.full(offer.price, currencyCode: offer.currencyCode)

        return "\(airlineText). Departs \(offer.departure.airportCode) at \(departureTime). "
            + "Arrives \(offer.arrival.airportCode) at \(arrivalTime)\(nextDaySuffix). "
            + "Duration \(durationPhrase). \(stopsPhrase). Starting from \(priceText)."
    }
}

// `@unchecked Sendable`: `set` only runs on the main actor, and `cancel` only
// from the ViewModel's `deinit`, which can't overlap a `set` because no other
// reference to the ViewModel exists by then. `Task.cancel()` is thread-safe.
private final class CancellableTaskBox: @unchecked Sendable {
    private var task: Task<Void, Never>?

    func set(_ task: Task<Void, Never>) {
        self.task = task
    }

    func cancel() {
        task?.cancel()
    }
}
