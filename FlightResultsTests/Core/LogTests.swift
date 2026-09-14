import XCTest
@testable import FlightResults

final class LogTests: XCTestCase {
    func test_redactsApiKey() throws {
        let url = try XCTUnwrap(URL(string: "https://serpapi.com/search?engine=google_flights&api_key=super-secret"))
        let redacted = Log.redact(url: url)
        XCTAssertFalse(redacted.contains("super-secret"))
        XCTAssertTrue(redacted.contains("api_key=***"))
    }

    func test_urlWithoutApiKey_isUnchanged() throws {
        let url = try XCTUnwrap(URL(string: "https://serpapi.com/search?engine=google_flights"))
        XCTAssertEqual(Log.redact(url: url), url.absoluteString)
    }
}
