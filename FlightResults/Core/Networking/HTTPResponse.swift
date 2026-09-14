import Foundation

struct HTTPResponse: Sendable {
    let data: Data
    let statusCode: Int
}
