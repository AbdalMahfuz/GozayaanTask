import Foundation

/// Spec 02 §1. `success` always holds at least 1 item — zero items is
/// `empty`, so the View never has to check for an empty array.
enum FlightResultsState: Equatable {
    case loading
    case success([FlightCardViewData])
    case empty(EmptyStateViewData)
    case error(ErrorStateViewData)
}
