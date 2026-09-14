import UIKit

@MainActor
final class FlightResultsCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let navigationController: UINavigationController
    private let environment: AppEnvironment

    init(navigationController: UINavigationController, environment: AppEnvironment) {
        self.navigationController = navigationController
        self.environment = environment
    }

    func start() {
        // Placeholder until the ViewModel and real screen exist (plan steps 7–9).
        let viewController = FlightResultsViewController()
        navigationController.setViewControllers([viewController], animated: false)
    }
}
