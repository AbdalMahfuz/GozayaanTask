import Foundation

/// Composition root: the only place that reads process info, launch arguments
/// and configuration to decide which implementations the app runs with.
/// Grows in later steps (data source selection, forced states); see spec 04 §4.
struct AppEnvironment: Sendable {
    let config: AppConfig

    static func make(bundle: Bundle = .main) -> AppEnvironment {
        AppEnvironment(config: .fromBundle(bundle))
    }

    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
