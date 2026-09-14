import Foundation

/// Values injected at build time through Config/*.xcconfig → Info.plist.
struct AppConfig: Sendable, Equatable {
    static let serpApiKeyInfoKey = "SERPAPI_API_KEY"

    /// `nil` when the key is missing, blank, or the build setting was never expanded.
    let serpApiKey: String?

    init(serpApiKey: String?) {
        self.serpApiKey = serpApiKey
    }

    init(infoDictionary: [String: Any]) {
        let raw = (infoDictionary[Self.serpApiKeyInfoKey] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isUnexpandedVariable = raw.hasPrefix("$(")
        serpApiKey = (raw.isEmpty || isUnexpandedVariable) ? nil : raw
    }

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfig {
        AppConfig(infoDictionary: bundle.infoDictionary ?? [:])
    }
}
