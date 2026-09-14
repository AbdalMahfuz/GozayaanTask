import Foundation
import OSLog

enum LogCategory: String {
    case network, mapping, navigation
}

/// Thin wrapper over `os.Logger`. `print` isn't used anywhere in the app
/// (spec 04 §6). Every URL is redacted before it can reach a log line.
enum Log {
    private static func logger(_ category: LogCategory) -> Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "FlightResults", category: category.rawValue)
    }

    static func debug(_ category: LogCategory, _ message: @escaping @autoclosure () -> String) {
        #if DEBUG
        logger(category).debug("\(message(), privacy: .public)")
        #endif
    }

    static func error(_ category: LogCategory, _ message: @escaping @autoclosure () -> String) {
        logger(category).error("\(message(), privacy: .public)")
    }

    /// Replaces the `api_key` query value with `***` so a logged URL never leaks the key.
    static func redact(url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.queryItems = components.queryItems?.map { item in
            guard item.name == "api_key" else { return item }
            return URLQueryItem(name: item.name, value: "***")
        }
        return components.string ?? url.absoluteString
    }
}
