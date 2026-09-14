import Foundation
@testable import FlightResults

@MainActor
final class SpyCoordinatorDelegate: FlightResultsCoordinatorDelegate {
    private(set) var selectedFlights: [FlightOffer] = []
    private(set) var selectedPromotions: [Promotion] = []

    func didSelectFlight(_ offer: FlightOffer) {
        selectedFlights.append(offer)
    }

    func didSelectPromotion(_ promotion: Promotion) {
        selectedPromotions.append(promotion)
    }
}
