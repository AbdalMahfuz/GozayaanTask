import UIKit

/// Pinned header (route header, date strip, sort/filter bar) + a scrolling
/// results area below. The results area's real layout/cells are built in
/// plan steps 10–14; for now it's an empty collection view (spec 05 §2).
final class FlightResultsViewController: UIViewController {
    private let viewModel: FlightResultsViewModel
    private let imageLoader: ImageLoading

    private let routeHeaderView = RouteHeaderView()
    private let dateFareStripView = DateFareStripView()
    private let sortFilterBarView = SortFilterBarView()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        return view
    }()

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

        // Cards, promotions, empty/error views: plan steps 10–14.
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
