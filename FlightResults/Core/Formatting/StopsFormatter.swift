import Foundation

/// Stops label and timeline dot count (spec 03 §4.6). "2 Stop", not "2 Stops" (D-13).
struct StopsFormatter {
    func label(for stops: Int) -> String {
        stops == 0 ? "Non-Stop" : "\(stops) Stop"
    }

    func dotCount(for stops: Int) -> Int {
        min(stops, 3)
    }
}
