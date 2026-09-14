import Foundation
@testable import FlightResults

/// Test double with two modes: return/throw immediately, or suspend until
/// the test explicitly resumes it (spec 04 §7 — used to test the `loading`
/// state while a request is in flight). Guarded by a lock since the
/// continuation is resumed from a different task than the one awaiting it.
final class MockFlightSearchService: FlightSearchService, @unchecked Sendable {
    enum Mode {
        case result(Result<[FlightOffer], Error>)
        case suspending
    }

    private let lock = NSLock()
    private var mode: Mode
    private var pendingContinuation: CheckedContinuation<[FlightOffer], Error>?
    private var _callCount = 0

    init(mode: Mode = .result(.success([]))) {
        self.mode = mode
    }

    var callCount: Int {
        withLock { _callCount }
    }

    func setMode(_ mode: Mode) {
        withLock { self.mode = mode }
    }

    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer] {
        let currentMode = withLock { () -> Mode in
            _callCount += 1
            return mode
        }

        switch currentMode {
        case .result(let result):
            return try result.get()
        case .suspending:
            return try await withCheckedThrowingContinuation { continuation in
                withLock { pendingContinuation = continuation }
            }
        }
    }

    func resume(with result: Result<[FlightOffer], Error>) {
        let continuation = withLock { () -> CheckedContinuation<[FlightOffer], Error>? in
            let value = pendingContinuation
            pendingContinuation = nil
            return value
        }
        continuation?.resume(with: result)
    }

    // `NSLock.lock()`/`.unlock()` are `noasync` in modern SDKs — calling
    // them directly inside an `async` function body doesn't compile. This
    // wrapper is itself synchronous, so `searchFlights` calls it as a plain
    // (non-async) function rather than touching the lock inline.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
