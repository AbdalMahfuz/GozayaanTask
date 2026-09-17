import UIKit
import XCTest
@testable import FlightResults

/// A7: the screen must not leak. This is the automated half of the Memory
/// Graph check — it builds the same object graph the Coordinator does
/// (ViewController + ViewModel + delegate), renders real cells, then drops
/// every strong reference and asserts nothing survives.
@MainActor
final class RetainCycleTests: XCTestCase {
    private let searchDate = Date(timeIntervalSince1970: 1_792_000_000)

    private func makeRequest() -> FlightSearchRequest {
        FlightSearchRequest(
            originCode: "DAC",
            destinationCode: "JFK",
            originCity: "Dhaka",
            destinationCity: "New York",
            outboundDate: searchDate,
            adults: 2,
            currencyCode: "BDT",
            tripType: .oneWay
        )
    }

    private func makeViewModel(service: FlightSearchService) -> FlightResultsViewModel {
        let dummy = DummyContentProvider.make(searchDate: searchDate)
        return FlightResultsViewModel(
            request: makeRequest(),
            service: service,
            promotions: dummy.promotions,
            dateFares: dummy.dateFares
        )
    }

    /// Renders the success state (cards + promo carousel) and then releases
    /// the screen. Catches a VC↔VM cycle through `onStateChange`, and a cell
    /// holding its controller through the image loader.
    func test_screen_deallocates_afterRenderingResults() async {
        weak var weakViewModel: FlightResultsViewModel?
        weak var weakViewController: FlightResultsViewController?
        weak var weakDelegate: SpyCoordinatorDelegate?

        var viewModel: FlightResultsViewModel? = makeViewModel(
            service: MockFlightSearchService(
                mode: .result(.success([FlightOffer.fake(id: "a", price: 100), FlightOffer.fake(id: "b", price: 200)]))
            )
        )
        var delegate: SpyCoordinatorDelegate? = SpyCoordinatorDelegate()
        viewModel?.coordinatorDelegate = delegate
        var viewController: FlightResultsViewController? = FlightResultsViewController(
            viewModel: viewModel!, imageLoader: StubImageLoader()
        )

        // No UIWindow: a key window is retained by UIKit itself and would
        // keep the controller alive past this test for reasons unrelated to
        // our own references.
        viewController?.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        viewController?.view.layoutIfNeeded()
        await viewModel?.load()
        viewController?.view.layoutIfNeeded()

        weakViewModel = viewModel
        weakViewController = viewController
        weakDelegate = delegate

        viewController = nil
        viewModel = nil
        delegate = nil

        // Let UIKit's autoreleased references go before asserting.
        await drainReleases()

        XCTAssertNil(weakViewController, "FlightResultsViewController leaked")
        XCTAssertNil(weakViewModel, "FlightResultsViewModel leaked")
        XCTAssertNil(weakDelegate, "Coordinator delegate leaked (should be weak from the ViewModel)")
    }

    /// Leaving the screen mid-search must not keep it alive through the
    /// in-flight `Task`.
    func test_screen_deallocates_whileSearchIsStillInFlight() async {
        weak var weakViewModel: FlightResultsViewModel?
        weak var weakViewController: FlightResultsViewController?
        let service = MockFlightSearchService(mode: .suspending)

        do {
            let viewModel = makeViewModel(service: service)
            let viewController = FlightResultsViewController(viewModel: viewModel, imageLoader: StubImageLoader())
            viewController.view.layoutIfNeeded() // viewDidLoad starts the search

            weakViewModel = viewModel
            weakViewController = viewController
        }

        await drainReleases()

        XCTAssertNil(weakViewController, "ViewController leaked while a search was in flight")
        XCTAssertNil(weakViewModel, "ViewModel leaked while a search was in flight")
    }
}

private extension RetainCycleTests {
    /// UIKit hands objects back through autorelease pools and the run loop,
    /// so a still-live reference right after `= nil` isn't proof of a cycle.
    func drainReleases() async {
        for _ in 0..<5 {
            await Task.yield()
            spinRunLoop()
        }
    }

    /// `RunLoop` is `noasync`, so the spin lives in a synchronous helper
    /// (same pattern as `MockFlightSearchService`'s lock wrapper).
    func spinRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }
}

private struct StubImageLoader: ImageLoading {
    func loadImage(from url: URL) async -> UIImage? { nil }
}
