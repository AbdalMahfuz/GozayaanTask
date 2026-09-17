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
        let splash = SplashViewController()
        splash.onFinished = { [weak self] in
            self?.showFlightResults()
        }
        window.rootViewController = splash
        window.makeKeyAndVisible()
    }

    private func showFlightResults() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let flightResults = FlightResultsCoordinator(
            navigationController: navigationController,
            environment: environment
        )
        childCoordinators.append(flightResults)
        flightResults.start()

        // Cross-dissolve so the splash doesn't cut abruptly; Reduce Motion
        // gets the plain swap.
        guard !UIAccessibility.isReduceMotionEnabled else {
            window.rootViewController = navigationController
            return
        }
        UIView.transition(with: window, duration: 0.3, options: [.transitionCrossDissolve]) {
            self.window.rootViewController = navigationController
        }
    }
}
