import XCTest
@testable import FlightResults

@MainActor
final class FlightResultsViewModelTests: XCTestCase {
    private let searchDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 14))!
    }()

    private lazy var request = FlightSearchRequest(
        originCode: "DAC",
        destinationCode: "JFK",
        originCity: "Dhaka",
        destinationCity: "New York",
        outboundDate: searchDate,
        adults: 2,
        currencyCode: "BDT",
        tripType: .oneWay
    )

    private lazy var defaultPromotions: [Promotion] = [
        Promotion(id: "p1", imageName: "promo_discount", title: "On International Flight Bookings", url: URL(string: "https://www.gozayaan.com")!)
    ]

    private func makeViewModel(
        service: MockFlightSearchService,
        promotions: [Promotion]? = nil
    ) -> FlightResultsViewModel {
        FlightResultsViewModel(
            request: request,
            service: service,
            promotions: promotions ?? defaultPromotions,
            dateFares: DummyContentProvider.make(searchDate: searchDate).dateFares
        )
    }

    private func waitUntil(timeout: Int = 5000, _ condition: () -> Bool) async {
        var iterations = 0
        while !condition() && iterations < timeout {
            await Task.yield()
            iterations += 1
        }
    }

    // MARK: - D: state

    func test_initialState_isLoading() {
        let viewModel = makeViewModel(service: MockFlightSearchService())
        XCTAssertEqual(viewModel.state, .loading)
    }

    func test_load_success_transitions() async {
        let cheap = FlightOffer.fake(id: "cheap", price: 100)
        let expensive = FlightOffer.fake(id: "expensive", price: 200)
        let service = MockFlightSearchService(mode: .result(.success([expensive, cheap])))
        let viewModel = makeViewModel(service: service)
        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }

        await viewModel.load()

        XCTAssertEqual(recorded.count, 2)
        XCTAssertEqual(recorded[0], .loading)
        guard case .success(let cards) = recorded[1] else { return XCTFail("expected success") }
        XCTAssertEqual(cards.map(\.id), ["cheap", "expensive"])
    }

    func test_load_empty_transitions() async {
        let service = MockFlightSearchService(mode: .result(.success([])))
        let viewModel = makeViewModel(service: service)
        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }

        await viewModel.load()

        XCTAssertEqual(recorded.count, 2)
        guard case .empty(let data) = recorded[1] else { return XCTFail("expected empty") }
        XCTAssertTrue(data.message.contains("DAC"))
        XCTAssertTrue(data.message.contains("JFK"))
        XCTAssertTrue(data.message.contains("14 Oct, 2026"))
    }

    func test_load_error_transitions() async {
        let service = MockFlightSearchService(mode: .result(.failure(FlightSearchError.offline)))
        let viewModel = makeViewModel(service: service)
        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }

        await viewModel.load()

        XCTAssertEqual(recorded.count, 2)
        guard case .error(let data) = recorded[1] else { return XCTFail("expected error") }
        XCTAssertEqual(data.kind, .connectivity)
        XCTAssertEqual(data.title, "No internet connection")
    }

    func test_errorMapping_allCases() async {
        let cases: [(FlightSearchError, ErrorStateViewData.Kind, String)] = [
            (.offline, .connectivity, "No internet connection"),
            (.timeout, .connectivity, "This is taking too long"),
            (.missingAPIKey, .general, "Search unavailable"),
            (.unauthorized, .general, "Search unavailable"),
            (.rateLimited, .general, "Too many searches"),
            (.server(status: 500, message: nil), .general, "Something went wrong"),
            (.decoding, .general, "Something went wrong"),
            (.unknown, .general, "Something went wrong")
        ]
        for (error, expectedKind, expectedTitle) in cases {
            let service = MockFlightSearchService(mode: .result(.failure(error)))
            let viewModel = makeViewModel(service: service)
            await viewModel.load()
            guard case .error(let data) = viewModel.state else { return XCTFail("expected error for \(error)") }
            XCTAssertEqual(data.kind, expectedKind, "for \(error)")
            XCTAssertEqual(data.title, expectedTitle, "for \(error)")
        }
    }

    func test_stateIsLoading_whileRequestInFlight() async {
        let service = MockFlightSearchService(mode: .suspending)
        let viewModel = makeViewModel(service: service)
        let task = Task { await viewModel.load() }

        await waitUntil { service.callCount == 1 }
        XCTAssertEqual(viewModel.state, .loading)

        service.resume(with: .success([.fake()]))
        await task.value
        guard case .success = viewModel.state else { return XCTFail("expected success") }
    }

    func test_retry_fromError_reloads() async {
        let service = MockFlightSearchService(mode: .result(.failure(FlightSearchError.offline)))
        let viewModel = makeViewModel(service: service)
        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }

        await viewModel.load()
        XCTAssertEqual(recorded.count, 2)

        service.setMode(.result(.success([.fake()])))
        viewModel.retry()
        await waitUntil { recorded.count == 4 }

        XCTAssertEqual(service.callCount, 2)
        XCTAssertEqual(recorded[2], .loading)
        guard case .success = recorded[3] else { return XCTFail("expected success") }
    }

    func test_concurrentLoad_isIgnored() async {
        let service = MockFlightSearchService(mode: .suspending)
        let viewModel = makeViewModel(service: service)

        async let first: Void = viewModel.load()
        async let second: Void = viewModel.load()
        await waitUntil { service.callCount >= 1 }
        await Task.yield()

        XCTAssertEqual(service.callCount, 1)
        service.resume(with: .success([]))
        _ = await (first, second)
    }

    func test_cancellation_doesNotEmitError() async {
        let service = MockFlightSearchService(mode: .result(.failure(CancellationError())))
        let viewModel = makeViewModel(service: service)
        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }

        await viewModel.load()

        XCTAssertEqual(recorded, [.loading])
        XCTAssertEqual(viewModel.state, .loading)
    }

    func test_cardViewData_formatting() async {
        let offer = FlightOffer.fake(
            id: "card1",
            airlineNames: ["Biman Bangladesh Airlines"],
            departureCode: "DAC",
            departure: LocalDateTime(year: 2026, month: 2, day: 15, hour: 4, minute: 0),
            arrivalCode: "CVB",
            arrival: LocalDateTime(year: 2026, month: 2, day: 16, hour: 8, minute: 20),
            arrivalDayOffset: 1,
            totalDurationMinutes: 1640,
            stops: 1,
            price: 78880,
            currencyCode: "BDT"
        )
        let service = MockFlightSearchService(mode: .result(.success([offer])))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()

        guard case .success(let cards) = viewModel.state, let card = cards.first else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(card.durationText, "27h 20m")
        XCTAssertEqual(card.stopsText, "1 Stop")
        XCTAssertEqual(card.arrivalDayOffsetText, "+1Day")
        XCTAssertEqual(card.priceText, "78,880")
        XCTAssertEqual(card.currencyCode, "BDT")
        XCTAssertEqual(card.departureTime, "04:00")
        XCTAssertEqual(card.arrivalTime, "08:20")
    }

    func test_headerViewData() {
        let viewModel = makeViewModel(service: MockFlightSearchService())
        XCTAssertEqual(viewModel.header.title, "Dhaka - New York")
        XCTAssertEqual(viewModel.header.dateText, "14 Oct, 2026")
        XCTAssertEqual(viewModel.header.passengerText, "02")
        XCTAssertEqual(viewModel.header.tripTypeText, "One Way")
    }

    func test_dateFares() {
        let viewModel = makeViewModel(service: MockFlightSearchService())
        XCTAssertEqual(viewModel.dateFares.count, 7)
        let selected = viewModel.dateFares[3]
        XCTAssertEqual(selected.dateText, "Wed 14 Oct")
        XCTAssertEqual(selected.priceText, "BDT 68,500")
        XCTAssertTrue(selected.isSelected)
    }

    // MARK: - E: sorting & intents

    func test_selectSort_resortsInPlace() async {
        let cheap = FlightOffer.fake(id: "cheap", totalDurationMinutes: 300, price: 100)
        let fast = FlightOffer.fake(id: "fast", totalDurationMinutes: 100, price: 300)
        let service = MockFlightSearchService(mode: .result(.success([cheap, fast])))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()
        guard case .success(let initialCards) = viewModel.state else { return XCTFail() }
        XCTAssertEqual(initialCards.map(\.id), ["cheap", "fast"])

        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }
        viewModel.selectSort(.fastest)

        XCTAssertEqual(recorded.count, 1)
        guard case .success(let reordered) = viewModel.state else { return XCTFail() }
        XCTAssertEqual(reordered.map(\.id), ["fast", "cheap"])
        XCTAssertEqual(Set(reordered.map(\.id)), Set(initialCards.map(\.id)))
    }

    func test_selectSameSort_doesNotEmit() async {
        let service = MockFlightSearchService(mode: .result(.success([.fake()])))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()

        var recorded: [FlightResultsState] = []
        viewModel.onStateChange = { recorded.append($0) }
        viewModel.selectSort(.cheapest)

        XCTAssertTrue(recorded.isEmpty)
    }

    func test_sortChosenDuringLoading_appliesToResults() async {
        let cheap = FlightOffer.fake(id: "cheap", totalDurationMinutes: 300, price: 100)
        let fast = FlightOffer.fake(id: "fast", totalDurationMinutes: 100, price: 300)
        let service = MockFlightSearchService(mode: .suspending)
        let viewModel = makeViewModel(service: service)
        let task = Task { await viewModel.load() }

        await waitUntil { service.callCount == 1 }
        viewModel.selectSort(.fastest)
        XCTAssertEqual(viewModel.sortOption, .fastest)

        service.resume(with: .success([cheap, fast]))
        await task.value

        guard case .success(let cards) = viewModel.state else { return XCTFail() }
        XCTAssertEqual(cards.map(\.id), ["fast", "cheap"])
    }

    func test_didSelectFlight_forwardsToDelegate() async {
        let offer = FlightOffer.fake(id: "abc")
        let service = MockFlightSearchService(mode: .result(.success([offer])))
        let viewModel = makeViewModel(service: service)
        let spy = SpyCoordinatorDelegate()
        viewModel.coordinatorDelegate = spy
        await viewModel.load()

        viewModel.didSelectFlight(id: "abc")
        XCTAssertEqual(spy.selectedFlights.map(\.id), ["abc"])

        viewModel.didSelectFlight(id: "unknown")
        XCTAssertEqual(spy.selectedFlights.count, 1)
    }

    func test_didSelectPromotion_forwardsToDelegate() {
        let promotion = Promotion(
            id: "p1", imageName: "promo_discount", title: "Title", url: URL(string: "https://www.gozayaan.com")!
        )
        let viewModel = makeViewModel(service: MockFlightSearchService(), promotions: [promotion])
        let spy = SpyCoordinatorDelegate()
        viewModel.coordinatorDelegate = spy

        viewModel.didSelectPromotion(id: "p1")
        XCTAssertEqual(spy.selectedPromotions.map(\.id), ["p1"])

        viewModel.didSelectPromotion(id: "unknown")
        XCTAssertEqual(spy.selectedPromotions.count, 1)
    }

    func test_delegate_isWeak() {
        let viewModel = makeViewModel(service: MockFlightSearchService())
        var spy: SpyCoordinatorDelegate? = SpyCoordinatorDelegate()
        viewModel.coordinatorDelegate = spy
        weak let weakSpy = spy
        spy = nil

        XCTAssertNil(weakSpy)
        XCTAssertNil(viewModel.coordinatorDelegate)
    }

    /// Releasing the ViewModel mid-search must deallocate it and cancel the
    /// request. Fails if the in-flight task holds `self` across the `await`.
    func test_releasingViewModel_cancelsInFlightSearch() async {
        let service = MockFlightSearchService(mode: .suspending)
        var viewModel: FlightResultsViewModel? = makeViewModel(service: service)
        weak let weakViewModel = viewModel

        viewModel?.start()
        await waitUntil { service.callCount == 1 }
        XCTAssertEqual(service.callCount, 1, "precondition: the search must actually be in flight")

        viewModel = nil
        await waitUntil { service.wasCancelled }

        XCTAssertNil(weakViewModel, "ViewModel stayed alive while its search was in flight")
        XCTAssertTrue(service.wasCancelled, "Releasing the ViewModel didn't cancel the search")
    }

    func test_viewModel_isReleased_whenNoExternalReferences() {
        var viewModel: FlightResultsViewModel? = makeViewModel(service: MockFlightSearchService())
        weak let weakViewModel = viewModel
        viewModel = nil

        XCTAssertNil(weakViewModel)
    }
}
