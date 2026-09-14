import Foundation

struct DateFare: Codable, Hashable, Sendable {
    let date: Date
    let price: Int
    let isSelected: Bool
}
