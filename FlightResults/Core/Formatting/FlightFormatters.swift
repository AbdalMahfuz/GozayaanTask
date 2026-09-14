import Foundation

/// One instance of each formatter, owned by the ViewModel on the main actor
/// (spec 03 §6). No `static` formatters anywhere (A11).
struct FlightFormatters {
    let price = PriceFormatter()
    let duration = DurationFormatter()
    let time = TimeFormatter()
    let dayOffset = DayOffsetFormatter()
    let stops = StopsFormatter()
    let headerDate = HeaderDateFormatter()
    let chipDate = ChipDateFormatter()
    let passenger = PassengerFormatter()

    init() {}
}
