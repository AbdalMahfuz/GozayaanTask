import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        self.window = window

        // Unit tests are hosted in the app. Don't start the real flow there,
        // so a test run never triggers a live SerpApi search (spec 04 §4).
        guard !AppEnvironment.isRunningUnitTests else {
            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
            return
        }

        let coordinator = AppCoordinator(window: window, environment: .make())
        appCoordinator = coordinator
        coordinator.start()
    }
}
