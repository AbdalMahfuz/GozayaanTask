import SafariServices
import UIKit

/// `SafariServices` is imported only here (A5) — the ViewModel never sees it.
@MainActor
final class FlightResultsCoordinator: Coordinator, FlightResultsCoordinatorDelegate {
    var childCoordinators: [Coordinator] = []

    private let navigationController: UINavigationController
    private let environment: AppEnvironment

    init(navigationController: UINavigationController, environment: AppEnvironment) {
        self.navigationController = navigationController
        self.environment = environment
    }

    func start() {
        let viewModel = FlightResultsViewModel(
            request: environment.searchRequest,
            service: environment.flightSearchService,
            promotions: environment.dummyContent.promotions,
            dateFares: environment.dummyContent.dateFares
        )
        viewModel.coordinatorDelegate = self

        let viewController = FlightResultsViewController(viewModel: viewModel, imageLoader: environment.imageLoader)
        navigationController.setViewControllers([viewController], animated: false)
    }

    // MARK: - FlightResultsCoordinatorDelegate

    func didSelectFlight(_ offer: FlightOffer) {
        // The brief's only requirement here is that the delegate call is
        // wired end to end; there's no details screen (D-18).
        Log.debug(.navigation, "Selected flight \(offer.id)")
    }

    func didSelectPromotion(_ promotion: Promotion) {
        guard let scheme = promotion.url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            Log.debug(.navigation, "Ignored non-http(s) promotion URL: \(promotion.url)")
            return
        }
        let safariViewController = SFSafariViewController(url: promotion.url)
        navigationController.present(safariViewController, animated: true)
    }
}
