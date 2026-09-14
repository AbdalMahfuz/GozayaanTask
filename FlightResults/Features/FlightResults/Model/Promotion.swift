import Foundation

struct Promotion: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let imageName: String
    let title: String
    let url: URL
}
