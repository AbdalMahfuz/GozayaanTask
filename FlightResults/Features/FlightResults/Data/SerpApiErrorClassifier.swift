import Foundation

/// Isolated string matching on SerpApi's free-text `error` field (spec 02 §4).
/// Brittle by nature; kept in one place with unit tests on the exact wording.
enum SerpApiErrorClassifier {
    static func isNoResultsMessage(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return lowered.contains("hasn't returned any results") || lowered.contains("no results")
    }

    static func isRateLimitMessage(_ message: String) -> Bool {
        message.lowercased().contains("run out of searches")
    }
}
