import Foundation

/// Foundation-only, so the ViewModel can refer to this without seeing UIKit
/// or the concrete `FlightResultsCoordinator` type (spec 04 §3.3, D-35).
@MainActor
protocol FlightResultsCoordinatorDelegate: AnyObject {
    func didSelectFlight(_ offer: FlightOffer)
    func didSelectPromotion(_ promotion: Promotion)
}
