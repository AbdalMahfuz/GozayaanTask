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
    private var _wasCancelled = false

    init(mode: Mode = .result(.success([]))) {
        self.mode = mode
    }

    var callCount: Int {
        withLock { _callCount }
    }

    /// True once a suspended search was cancelled by its task.
    var wasCancelled: Bool {
        withLock { _wasCancelled }
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
            // Cancellation-aware, like `URLSession`: a cancelled task resumes
            // with `CancellationError` instead of hanging forever. Handles a
            // cancel that lands before the continuation is stored, too.
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    let alreadyCancelled = withLock { () -> Bool in
                        if _wasCancelled { return true }
                        pendingContinuation = continuation
                        return false
                    }
                    if alreadyCancelled {
                        continuation.resume(throwing: CancellationError())
                    }
                }
            } onCancel: {
                let continuation = withLock { () -> CheckedContinuation<[FlightOffer], Error>? in
                    _wasCancelled = true
                    let value = pendingContinuation
                    pendingContinuation = nil
                    return value
                }
                continuation?.resume(throwing: CancellationError())
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
