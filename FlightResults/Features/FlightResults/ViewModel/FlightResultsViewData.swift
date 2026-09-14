import Foundation

// ViewData types built by the ViewModel and rendered by Views (spec 03 §7).
// Foundation-only: no formatting or model types leak into the View layer
// beyond these plain value types.

struct RouteHeaderViewData: Equatable {
    let title: String
    let dateText: String
    let passengerText: String
    let tripTypeText: String
}

struct DateFareViewData: Hashable {
    let dateText: String
    let priceText: String
    let isSelected: Bool
}

/// Synthesized `Equatable` over ALL fields (not id-only) — content changes
/// for an existing id must be detectable so `reconfigureItems` can apply them.
struct FlightCardViewData: Hashable, Identifiable {
    let id: String
    let airlineText: String
    let airlineLogoURL: URL?
    let departureTime: String
    let departureCode: String
    let arrivalTime: String
    let arrivalDayOffsetText: String?
    let arrivalCode: String
    let durationText: String
    let stopsText: String
    let stopDotCount: Int
    let currencyCode: String
    let priceText: String
    let accessibilityLabel: String
}

struct PromotionViewData: Hashable, Identifiable {
    let id: String
    let imageName: String
    let title: String
    let linkText: String
}

struct EmptyStateViewData: Equatable {
    let title: String
    let message: String
}

struct ErrorStateViewData: Equatable {
    let kind: Kind
    let title: String
    let message: String
    let debugDetail: String?

    enum Kind {
        case connectivity, general
    }
}
