import XCTest
@testable import FlightResults

final class FormatterTests: XCTestCase {
    func test_price() {
        let formatter = PriceFormatter()
        let cases: [(Int, String)] = [
            (0, "0"), (999, "999"), (1000, "1,000"),
            (37400, "37,400"), (120400, "120,400"), (1234567, "1,234,567")
        ]
        for (input, expected) in cases {
            XCTAssertEqual(formatter.amount(input), expected)
        }
    }

    func test_price_isLocaleIndependent() {
        // `en_US_POSIX` is fixed inside the formatter's own `NumberFormatter`,
        // so it never reads `Locale.current` — asserting the same output
        // regardless of what the device locale happens to be (F1: bn_BD, hi_IN).
        let formatter = PriceFormatter()
        XCTAssertEqual(formatter.amount(120400), "120,400")
    }

    func test_duration() {
        let formatter = DurationFormatter()
        XCTAssertEqual(formatter.string(from: 45), "45m")
        XCTAssertEqual(formatter.string(from: 60), "1h")
        XCTAssertEqual(formatter.string(from: 280), "4h 40m")
        XCTAssertEqual(formatter.string(from: 1640), "27h 20m")
        XCTAssertEqual(formatter.string(from: 3020), "50h 20m")
    }

    func test_dayOffset() {
        let formatter = DayOffsetFormatter()
        XCTAssertNil(formatter.string(from: 0))
        XCTAssertEqual(formatter.string(from: 1), "+1Day")
        XCTAssertEqual(formatter.string(from: 2), "+2Day")
        XCTAssertEqual(formatter.string(from: -1), "-1Day")
    }

    func test_stops() {
        let formatter = StopsFormatter()
        XCTAssertEqual(formatter.label(for: 0), "Non-Stop")
        XCTAssertEqual(formatter.label(for: 1), "1 Stop")
        XCTAssertEqual(formatter.label(for: 2), "2 Stop")
        XCTAssertEqual(formatter.label(for: 3), "3 Stop")
        XCTAssertEqual(formatter.dotCount(for: 0), 0)
        XCTAssertEqual(formatter.dotCount(for: 1), 1)
        XCTAssertEqual(formatter.dotCount(for: 2), 2)
        XCTAssertEqual(formatter.dotCount(for: 3), 3)
        XCTAssertEqual(formatter.dotCount(for: 5), 3)
    }

    func test_dates_and_passengers() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let headerDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let chipDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 8))! // a Sunday

        XCTAssertEqual(HeaderDateFormatter().string(from: headerDate), "15 Feb, 2026")
        XCTAssertEqual(ChipDateFormatter().string(from: chipDate), "Sun 08 Feb")
        XCTAssertEqual(PassengerFormatter().string(from: 2), "02")
        XCTAssertEqual(PassengerFormatter().string(from: 1), "01")
        XCTAssertEqual(PassengerFormatter().string(from: 12), "12")
    }

    func test_time() {
        let time = TimeFormatter().string(from: LocalDateTime(year: 2026, month: 2, day: 15, hour: 4, minute: 0))
        XCTAssertEqual(time, "04:00")
    }
}
