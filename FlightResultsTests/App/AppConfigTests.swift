import XCTest
@testable import FlightResults

final class AppConfigTests: XCTestCase {
    func test_readsKey() {
        let config = AppConfig(infoDictionary: ["SERPAPI_API_KEY": "abc123"])
        XCTAssertEqual(config.serpApiKey, "abc123")
    }

    func test_trimsWhitespace() {
        let config = AppConfig(infoDictionary: ["SERPAPI_API_KEY": "  abc123\n"])
        XCTAssertEqual(config.serpApiKey, "abc123")
    }

    func test_missingKey_isNil() {
        XCTAssertNil(AppConfig(infoDictionary: [:]).serpApiKey)
    }

    func test_emptyKey_isNil() {
        XCTAssertNil(AppConfig(infoDictionary: ["SERPAPI_API_KEY": "   "]).serpApiKey)
    }

    func test_unexpandedBuildSetting_isNil() {
        XCTAssertNil(AppConfig(infoDictionary: ["SERPAPI_API_KEY": "$(SERPAPI_API_KEY)"]).serpApiKey)
    }

    func test_nonStringValue_isNil() {
        XCTAssertNil(AppConfig(infoDictionary: ["SERPAPI_API_KEY": 42]).serpApiKey)
    }
}
