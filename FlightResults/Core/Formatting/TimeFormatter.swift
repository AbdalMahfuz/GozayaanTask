import Foundation

/// `LocalDateTime` → `"HH:mm"`, no `DateFormatter` needed (spec 03 §6).
struct TimeFormatter {
    func string(from localDateTime: LocalDateTime) -> String {
        String(format: "%02d:%02d", localDateTime.hour, localDateTime.minute)
    }
}
