import Foundation

extension JSONDecoder {
    /// `JSONDecoder` isn't `Sendable`, so this creates a fresh instance per
    /// call rather than exposing a shared one (spec 04 §3.4).
    static var serpApi: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
