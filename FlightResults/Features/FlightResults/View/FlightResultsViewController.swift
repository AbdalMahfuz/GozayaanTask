import UIKit

/// Pinned header (route header, date strip, sort/filter bar) + a scrolling
/// results area below, covering the loading, success, empty and error
/// states (spec 02).
final class FlightResultsViewController: UIViewController {
    private let viewModel: FlightResultsViewModel
    private let imageLoader: ImageLoading

    private let routeHeaderView = RouteHeaderView()
    private let dateFareStripView = DateFareStripView()
    private let sortFilterBarView = SortFilterBarView()
    private let emptyStateView = EmptyStateView()
    private let errorStateView = ErrorStateView()

    // Items carry ids only; content is looked up here, rebuilt on every
    // render (spec 04 §3.5).
    private var cardsByID: [String: FlightCardViewData] = [:]
    private var sortDropdownView: SortDropdownView?
    // Tracks whether the *previous* render was `.success`, so a fresh set of
    // results (e.g. after retry) scrolls to the top, but a re-sort of the
    // same results doesn't (spec 02 §2.2).
    private var wasShowingSuccess = false

    private lazy var collectionView: UICollectionView = {
        // Guard `dataSource` — this layout callback can run while the CV is
        // still being created, before `makeDataSource()` has assigned it.
        let layout = FlightResultsLayout.make { [weak self] index in
            self?.dataSource?.snapshot().sectionIdentifiers[safe: index]
        }
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.delegate = self
        return view
    }()

    // Built once in `viewDidLoad` via `makeDataSource()`. Must not be `lazy`:
    // a lazy data source (or lazy registration) first touched from the cell
    // provider is flagged by UIKit as "registration created inside cell provider".
    private var dataSource: UICollectionViewDiffableDataSource<FlightResultsSection, FlightResultsItem>!

    init(viewModel: FlightResultsViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.navy

        // Data source + registration before the CV joins the hierarchy, so the
        // first layout pass never constructs them from inside a cell request.
        dataSource = makeDataSource()
        setUpLayout()
        routeHeaderView.configure(with: viewModel.header)
        sortFilterBarView.onSortTapped = { [weak self] in
            self?.toggleSort()
        }
        errorStateView.onRetry = { [weak self] in
            self?.viewModel.retry()
        }

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
        viewModel.start()
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<FlightResultsSection, FlightResultsItem> {
        let cardRegistration = UICollectionView.CellRegistration<FlightCardCell, String> { [weak self] cell, _, id in
            guard let self, let card = cardsByID[id] else { return }
            cell.configure(with: card, imageLoader: imageLoader)
        }
        let promoRegistration = UICollectionView.CellRegistration<PromoCardCell, String> { [weak self] cell, _, id in
            guard let promotion = self?.viewModel.promotions.first(where: { $0.id == id }) else { return }
            cell.configure(with: promotion)
        }
        let bannerRegistration = UICollectionView.CellRegistration<LoadingBannerCell, Void> { _, _, _ in }
        let skeletonRegistration = UICollectionView.CellRegistration<SkeletonCardCell, Int> { _, _, _ in }
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .flight(let id):
                return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath, item: id)
            case .promotion(let id):
                return collectionView.dequeueConfiguredReusableCell(using: promoRegistration, for: indexPath, item: id)
            case .loadingBanner:
                return collectionView.dequeueConfiguredReusableCell(using: bannerRegistration, for: indexPath, item: ())
            case .skeleton(let index):
                return collectionView.dequeueConfiguredReusableCell(using: skeletonRegistration, for: indexPath, item: index)
            }
        }
    }

    private func setUpLayout() {
        [routeHeaderView, dateFareStripView, sortFilterBarView, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            routeHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            routeHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            routeHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dateFareStripView.topAnchor.constraint(equalTo: routeHeaderView.bottomAnchor),
            dateFareStripView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dateFareStripView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dateFareStripView.heightAnchor.constraint(
                equalToConstant: Theme.Spacing.chipHeight + 1
            ),

            sortFilterBarView.topAnchor.constraint(equalTo: dateFareStripView.bottomAnchor, constant: 16),
            sortFilterBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortFilterBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sortFilterBarView.heightAnchor.constraint(equalToConstant: 32),

            collectionView.topAnchor.constraint(equalTo: sortFilterBarView.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func render(_ state: FlightResultsState) {
        let isLoading: Bool
        let sortEnabled: Bool
        switch state {
        case .loading:
            isLoading = true
            sortEnabled = true
        case .success:
            isLoading = false
            sortEnabled = true
        case .empty, .error:
            isLoading = false
            sortEnabled = false
        }

        dateFareStripView.configure(dateFares: viewModel.dateFares, isLoading: isLoading)
        sortFilterBarView.configure(sortTitle: viewModel.sortOption.displayTitle, isEnabled: sortEnabled)
        if let dropdown = sortDropdownView {
            dropdown.configure(selected: viewModel.sortOption)
        }

        var snapshot = NSDiffableDataSourceSnapshot<FlightResultsSection, FlightResultsItem>()
        collectionView.backgroundView = nil
        var isNewResults = false
        switch state {
        case .loading:
            cardsByID = [:]
            wasShowingSuccess = false
            snapshot.appendSections([.loadingBanner])
            snapshot.appendItems([.loadingBanner], toSection: .loadingBanner)
            appendCarouselSplit(
                items: (0..<3).map { FlightResultsItem.skeleton($0) },
                topSection: .skeletonTop,
                bottomSection: .skeletonBottom,
                to: &snapshot
            )
        case .success(let cards):
            cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            isNewResults = !wasShowingSuccess
            wasShowingSuccess = true
            // Carousel after the 2nd card, or after the last card with fewer
            // than 2 (D-22).
            appendCarouselSplit(
                items: cards.map { .flight(id: $0.id) },
                topSection: .listTop,
                bottomSection: .listBottom,
                to: &snapshot
            )
        case .empty(let data):
            cardsByID = [:]
            wasShowingSuccess = false
            emptyStateView.configure(with: data)
            collectionView.backgroundView = emptyStateView
        case .error(let data):
            cardsByID = [:]
            wasShowingSuccess = false
            errorStateView.configure(with: data)
            collectionView.backgroundView = errorStateView
        }
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard isNewResults else { return }
            self?.collectionView.setContentOffset(.zero, animated: false)
        }
    }

    /// Places the promo carousel after the 2nd item, or after the last item
    /// if there are fewer than 2 (D-22; loading uses the same rule over its
    /// 3 skeletons, spec 02 §2 table).
    private func appendCarouselSplit(
        items: [FlightResultsItem],
        topSection: FlightResultsSection,
        bottomSection: FlightResultsSection,
        to snapshot: inout NSDiffableDataSourceSnapshot<FlightResultsSection, FlightResultsItem>
    ) {
        let splitIndex = min(2, items.count)
        let topItems = items[..<splitIndex]
        let bottomItems = items[splitIndex...]

        snapshot.appendSections([topSection])
        snapshot.appendItems(Array(topItems), toSection: topSection)

        if !viewModel.promotions.isEmpty {
            snapshot.appendSections([.promotions])
            snapshot.appendItems(viewModel.promotions.map { .promotion(id: $0.id) }, toSection: .promotions)
        }

        if !bottomItems.isEmpty {
            snapshot.appendSections([bottomSection])
            snapshot.appendItems(Array(bottomItems), toSection: bottomSection)
        }
    }

    private func toggleSort() {
        if let dropdown = sortDropdownView {
            closeDropdown(dropdown)
        } else {
            openDropdown()
        }
    }

    private func openDropdown() {
        let dropdown = SortDropdownView()
        dropdown.configure(selected: viewModel.sortOption)
        dropdown.onSelect = { [weak self] option in
            guard let self else { return }
            viewModel.selectSort(option)
            if let dropdown = sortDropdownView {
                closeDropdown(dropdown)
            }
        }
        dropdown.onDismissTapped = { [weak self] in
            guard let self, let dropdown = sortDropdownView else { return }
            closeDropdown(dropdown)
        }
        dropdown.show(
            in: view,
            anchorLeading: view.leadingAnchor,
            anchorBottom: sortFilterBarView.sortButton.bottomAnchor
        )
        sortDropdownView = dropdown
        sortFilterBarView.setDropdownExpanded(true)
    }

    private func closeDropdown(_ dropdown: SortDropdownView) {
        dropdown.hide()
        sortDropdownView = nil
        sortFilterBarView.setDropdownExpanded(false)
    }
}

extension FlightResultsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath) {
        case .flight(let id):
            viewModel.didSelectFlight(id: id)
        case .promotion(let id):
            viewModel.didSelectPromotion(id: id)
        case .loadingBanner, .skeleton, .none:
            break
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
