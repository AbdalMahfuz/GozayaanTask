import UIKit

/// Spec 04 §3.5. Items carry ids only — content is looked up by id from a
/// dictionary rebuilt on each `render`, so re-sorting animates as moves
/// instead of delete+insert.
enum FlightResultsSection: Hashable {
    case loadingBanner, skeletonTop, listTop, promotions, skeletonBottom, listBottom
}

enum FlightResultsItem: Hashable {
    case loadingBanner
    case skeleton(Int)
    case flight(id: String)
    case promotion(id: String)
}

@MainActor
enum FlightResultsLayout {
    static func make(sectionFor: @escaping (Int) -> FlightResultsSection?) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionFor(sectionIndex) {
            case .loadingBanner:
                return bannerSection()
            case .promotions:
                return promotionsSection()
            case .skeletonTop, .skeletonBottom:
                return listSection(
                    estimatedHeight: 116,
                    interGroupSpacing: Theme.Spacing.skeletonSpacing
                )
            case .listTop, .listBottom, .none:
                return listSection(
                    estimatedHeight: 180,
                    interGroupSpacing: Theme.Spacing.cardSpacing
                )
            }
        }
    }

    private static func listSection(
        estimatedHeight: CGFloat,
        interGroupSpacing: CGFloat
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(estimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: Theme.Spacing.screenInset, bottom: 0, trailing: Theme.Spacing.screenInset
        )
        section.interGroupSpacing = interGroupSpacing
        return section
    }

    private static func bannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: Theme.Spacing.screenInset, bottom: 0, trailing: Theme.Spacing.screenInset
        )
        return section
    }

    private static func promotionsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(204), heightDimension: .absolute(52))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Theme.Spacing.screenInset, leading: Theme.Spacing.screenInset,
            bottom: Theme.Spacing.screenInset, trailing: Theme.Spacing.screenInset
        )
        return section
    }
}
