import UIKit

@MainActor
final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let environment: AppEnvironment

    init(window: UIWindow, environment: AppEnvironment) {
        self.window = window
        self.environment = environment
    }

    func start() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let flightResults = FlightResultsCoordinator(
            navigationController: navigationController,
            environment: environment
        )
        childCoordinators.append(flightResults)
        flightResults.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
