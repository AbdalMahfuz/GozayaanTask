import UIKit

/// Pinned header (route header, date strip, sort/filter bar) + a scrolling
/// results area below. Skeletons, promo carousel and empty/error views are
/// built in plan steps 11–13; for now only the success-state flight cards
/// render (plan step 10, spec 05 §2–§3.1).
final class FlightResultsViewController: UIViewController {
    private let viewModel: FlightResultsViewModel
    private let imageLoader: ImageLoading

    private let routeHeaderView = RouteHeaderView()
    private let dateFareStripView = DateFareStripView()
    private let sortFilterBarView = SortFilterBarView()

    // Items carry ids only; content is looked up here, rebuilt on every
    // render (spec 04 §3.5).
    private var cardsByID: [String: FlightCardViewData] = [:]

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

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
        viewModel.start()
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<FlightResultsSection, FlightResultsItem> {
        let registration = UICollectionView.CellRegistration<FlightCardCell, String> { [weak self] cell, _, id in
            guard let self, let card = cardsByID[id] else { return }
            cell.configure(with: card, imageLoader: imageLoader)
        }
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .flight(let id):
                return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
            case .loadingBanner, .skeleton, .promotion:
                // Built in plan steps 11–12.
                return UICollectionViewCell()
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
            dateFareStripView.heightAnchor.constraint(equalToConstant: 65),

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
        sortFilterBarView.configure(
            sortTitle: viewModel.sortOption == .cheapest ? "Cheapest" : "Fastest",
            isEnabled: sortEnabled
        )

        var snapshot = NSDiffableDataSourceSnapshot<FlightResultsSection, FlightResultsItem>()
        if case .success(let cards) = state {
            cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            snapshot.appendSections([.listTop])
            snapshot.appendItems(cards.map { .flight(id: $0.id) }, toSection: .listTop)
        } else {
            cardsByID = [:]
        }
        dataSource.apply(snapshot, animatingDifferences: true)

        // Skeletons, promo carousel, empty/error views: plan steps 11–13.
    }

    // Temporary stand-in until plan step 14 adds `SortDropdownView`: cycles
    // the two options directly so the ViewModel's sorting is exercisable
    // end to end before the real dropdown exists. Replaced, not kept, in
    // step 14.
    private func toggleSort() {
        let next: SortOption = viewModel.sortOption == .cheapest ? .fastest : .cheapest
        viewModel.selectSort(next)
        sortFilterBarView.configure(sortTitle: next == .cheapest ? "Cheapest" : "Fastest", isEnabled: true)
    }
}

extension FlightResultsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .flight(let id) = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.didSelectFlight(id: id)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
