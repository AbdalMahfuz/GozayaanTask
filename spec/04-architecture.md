# 04 — Architecture (MVVM + Coordinator)

## 1. Layers and who owns what

```
┌──────────────────────────────────────────────────────────────────────┐
│ App / Composition root   SceneDelegate · AppCoordinator · AppEnvironment │
│   builds every dependency, reads launch args + config, starts coordinators │
└───────────────┬──────────────────────────────────────────────────────┘
                │ creates & retains
┌───────────────▼───────────────┐        implements
│ FlightResultsCoordinator      │◄──────────── FlightResultsCoordinatorDelegate
│ UIKit + SafariServices        │                      ▲ (weak)
│ owns UINavigationController   │                      │ reports events
└───────┬───────────────────────┘                      │
        │ creates VC + VM, sets vm.coordinatorDelegate  │
┌───────▼──────────────────────┐  binds / intents  ┌───┴──────────────────────┐
│ View: FlightResultsVC + views│ ────────────────► │ FlightResultsViewModel   │
│ UIKit only, no logic         │ ◄──────────────── │ Foundation only          │
└──────────────────────────────┘ onStateChange     └───┬──────────────────────┘
                                                        │ protocol
                                   ┌────────────────────▼───────────────────┐
                                   │ Data: FlightSearchService (protocol)   │
                                   │  SerpApiFlightSearchService            │
                                   │   ├─ FlightsDataSource (protocol)      │
                                   │   │    Remote · CachedDecorator · Fixture│
                                   │   ├─ JSONDecoder → DTOs                │
                                   │   └─ FlightOfferMapper → [FlightOffer] │
                                   └────────────────────────────────────────┘
```

| Layer | Owns | Must NOT |
|---|---|---|
| **Model** | `FlightOffer`, `FlightSearchRequest`, `Promotion`, `DateFare`, `SortOption`; DTOs; mapper | Import UIKit; know about formatting or views |
| **Data** | HTTP, request building, decoding, error classification, caching, fixtures | Import UIKit; hold UI state |
| **ViewModel** | Screen state, the search call, sort logic, ViewData formatting, turning user intents into delegate calls | Import **UIKit** (at all), `SafariServices`, or anything from the Coordinator module; hold a strong reference to the delegate; call `UIApplication.open` |
| **View** (VC + subviews) | Layout, rendering ViewData, animations, forwarding user actions to the ViewModel | Call the service; format prices or dates; sort; know the Coordinator exists; hold `FlightOffer` |
| **Coordinator** | Building the screen (DI), navigation, presenting Safari | Hold screen state; do networking |
| **Composition root** | Choosing implementations (live / fixture / forced state), reading config and launch args | Leak `#if DEBUG` switches into features |

### Import rules (checked by review and by the grep in AC-A1..A4)
| Folder | Allowed imports |
|---|---|
| `Features/FlightResults/Model`, `Data`, `ViewModel`, `Core/Formatting`, `Core/Networking` | `Foundation` only (plus `OSLog`) |
| `Features/FlightResults/View`, `Core/UI` | `UIKit` |
| `Features/FlightResults/Coordinator`, `App` | `UIKit`, `SafariServices` |

## 2. Project structure

```
FlightResults.xcodeproj                      ← repo root (brief); repo = workspace/FlightResults/
FlightResults/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift                  window + AppCoordinator.start()
│   ├── AppCoordinator.swift
│   ├── AppEnvironment.swift                 composition root: picks data source / forced state
│   └── AppConfig.swift                      reads SERPAPI_API_KEY from Info.plist
├── Core/
│   ├── Coordinator/Coordinator.swift        protocol
│   ├── Networking/
│   │   ├── HTTPClient.swift                 protocol + URLSessionHTTPClient
│   │   └── HTTPResponse.swift
│   ├── Formatting/                          Price/Duration/Time/DayOffset/Stops/Date/Passenger formatters
│   ├── Logging/Log.swift                    OSLog wrapper, redacts api_key
│   └── UI/                                  Theme (Colors, Typography, Spacing), ShimmerView, ImageLoader, DashedLineView
├── Features/FlightResults/
│   ├── Coordinator/
│   │   ├── FlightResultsCoordinator.swift
│   │   └── FlightResultsCoordinatorDelegate.swift   (protocol; Foundation-only file)
│   ├── Model/        FlightOffer, FlightEndpoint, LocalDateTime, FlightSearchRequest, Promotion, DateFare, SortOption
│   ├── Data/
│   │   ├── DTO/SerpApiFlightsResponse.swift
│   │   ├── FlightOfferMapper.swift
│   │   ├── FlightSearchService.swift        protocol
│   │   ├── SerpApiFlightSearchService.swift
│   │   ├── SerpApiRequestBuilder.swift
│   │   ├── SerpApiErrorClassifier.swift
│   │   ├── FlightSearchError.swift
│   │   ├── FlightsDataSource.swift          protocol + RemoteFlightsDataSource
│   │   ├── CachedFlightsDataSource.swift    DEBUG decorator
│   │   ├── FixtureFlightsDataSource.swift
│   │   ├── StubFlightSearchService.swift    forced states (DEBUG)
│   │   └── DummyContentProvider.swift       promotions + date fares
│   ├── ViewModel/
│   │   ├── FlightResultsViewModel.swift
│   │   ├── FlightResultsState.swift
│   │   ├── FlightResultsViewData.swift
│   │   └── FlightOfferSorter.swift
│   └── View/
│       ├── FlightResultsViewController.swift
│       ├── Header/RouteHeaderView.swift
│       ├── Header/DateFareStripView.swift, DateFareChipCell.swift
│       ├── Header/SortFilterBarView.swift, SortDropdownView.swift
│       ├── List/FlightCardCell.swift, FlightTimelineView.swift
│       ├── List/SkeletonCardCell.swift, LoadingBannerCell.swift
│       ├── List/PromoCardCell.swift
│       ├── List/FlightResultsLayout.swift   compositional layout
│       └── States/EmptyStateView.swift, ErrorStateView.swift
├── Resources/
│   ├── Assets.xcassets                      AppIcon, promo_discount (own artwork), coin icon, airline placeholder
│   ├── Fixtures/serpapi_dac_jfk_oneway.json
│   └── LaunchScreen.storyboard
└── Info.plist
Config/
├── Base.xcconfig                            #include? "Secrets.xcconfig"
├── Secrets.example.xcconfig                 committed
└── Secrets.xcconfig                         git-ignored
FlightResultsTests/
├── Mapping/FlightOfferMapperTests.swift
├── Data/SerpApiFlightSearchServiceTests.swift, SerpApiRequestBuilderTests.swift, DecodingTests.swift
├── ViewModel/FlightResultsViewModelTests.swift, FlightOfferSorterTests.swift
├── Formatting/FormatterTests.swift
├── Support/MockFlightSearchService.swift, MockHTTPClient.swift, FixtureLoader.swift, FlightOffer+Fake.swift, SpyCoordinatorDelegate.swift
└── Fixtures/*.json
spec/  README.md  NOTES.md  .gitignore
```

`#include?` (with the `?`) means the build still works without `Secrets.xcconfig`. The key is then empty, which produces the `.missingAPIKey` error state.

## 3. Key types & signatures

### 3.1 Coordinator
```swift
@MainActor
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

@MainActor
final class AppCoordinator: Coordinator {
    init(window: UIWindow, environment: AppEnvironment)
    func start()   // creates UINavigationController (navigationBar hidden), starts FlightResultsCoordinator, stores it as child
}

@MainActor
final class FlightResultsCoordinator: Coordinator, FlightResultsCoordinatorDelegate {
    init(navigationController: UINavigationController, environment: AppEnvironment)
    func start()   // builds VM(service, request, dummy content), sets vm.coordinatorDelegate = self,
                   // builds VC(viewModel:), setViewControllers([vc], animated: false)
    func didSelectFlight(_ offer: FlightOffer)          // Log only (D-18)
    func didSelectPromotion(_ promotion: Promotion)     // http(s) check → SFSafariViewController present
}
```
Ownership: `SceneDelegate` → `AppCoordinator` (strong) → `childCoordinators` (strong) → `navigationController` (strong) → VC (strong) → VM (strong). The VM holds the Coordinator **weakly** through the delegate, so there is **no retain cycle**.

### 3.2 ViewModel
```swift
@MainActor
final class FlightResultsViewModel {
    // Outputs
    private(set) var state: FlightResultsState = .loading
    private(set) var sortOption: SortOption = .cheapest
    let header: RouteHeaderViewData
    let dateFares: [DateFareViewData]
    let promotions: [PromotionViewData]
    var onStateChange: ((FlightResultsState) -> Void)?
    var onSortOptionChange: ((SortOption) -> Void)?

    weak var coordinatorDelegate: FlightResultsCoordinatorDelegate?

    init(request: FlightSearchRequest,
         service: FlightSearchService,
         promotions: [Promotion],
         dateFares: [DateFare],
         formatters: FlightFormatters = .init())

    // Inputs (intents from the View)
    func start()                              // viewDidLoad → Task { await load() }, keeps task handle
    func load() async                         // the testable core; ignores re-entry while loading
    func retry()                              // error → start()
    func selectSort(_ option: SortOption)
    func didSelectFlight(id: String)          // finds FlightOffer by id → delegate
    func didSelectPromotion(id: String)       // finds Promotion by id → delegate

    // Internal
    private var offers: [FlightOffer] = []    // unsorted, as returned by the service
    private var loadTask: Task<Void, Never>?
    private var generation = 0
}
```

Load outline, which reviewers must be able to trace. It's split into a synchronous begin and finish, so the waiting in between holds **only the service and request, never the ViewModel**:
```
start():
    guard let pending = beginLoad() else { return }     // re-entry guard, generation += 1, state = .loading
    task = Task { [weak self] in
        let outcome = await search(pending)              // no reference to self while waiting
        self?.finishLoad(outcome, generation: pending.generation)
    }

finishLoad(outcome, generation):
    isLoading = false
    guard generation == current, !Task.isCancelled else { return }
    .success(result) → offers = result; .empty or .success(sorted cards)
    .failure(CancellationError) → no state change
    .failure(error) → .error(makeErrorData(FlightSearchError(error)))
```
`load()` runs the same three steps awaited in place, for tests.

`deinit` cancels the task. Swift 6: `deinit` isn't main-actor-isolated, so the task handle lives in a `nonisolated let` box that `deinit` can reach.

**Why the split matters:** the first version was `Task { [weak self] in guard let self else { return }; await self.load() }`. `guard let self` makes a strong reference that lasts across the `await`, so the task kept the ViewModel alive until the request finished — and `deinit`, the thing meant to cancel it, could never run first. Leaving the screen mid-search didn't cancel anything (NOTES #18). Covered by `test_releasingViewModel_cancelsInFlightSearch`.

### 3.3 The delegate protocol
In `FlightResultsCoordinatorDelegate.swift`, importing **Foundation only**, so the ViewModel can refer to it without seeing UIKit:
```swift
@MainActor
protocol FlightResultsCoordinatorDelegate: AnyObject {
    func didSelectFlight(_ offer: FlightOffer)
    func didSelectPromotion(_ promotion: Promotion)
}
```
The ViewModel only knows *this protocol*. It never sees the concrete `FlightResultsCoordinator` type, so it "doesn't know the Coordinator exists".

### 3.4 Data
```swift
protocol FlightSearchService: Sendable {
    func searchFlights(_ request: FlightSearchRequest) async throws -> [FlightOffer]   // throws FlightSearchError / CancellationError
}

protocol FlightsDataSource: Sendable {
    func fetch(_ request: FlightSearchRequest) async throws -> HTTPResponse          // (data, statusCode)
}

protocol HTTPClient: Sendable {
    func send(_ urlRequest: URLRequest) async throws -> HTTPResponse
}

struct SerpApiFlightSearchService: FlightSearchService {
    init(dataSource: FlightsDataSource, mapper: FlightOfferMapper = .init(), decoder: JSONDecoder = .serpApi)
}
struct RemoteFlightsDataSource: FlightsDataSource { init(client: HTTPClient, apiKey: String?) }   // nil/empty key → throws .missingAPIKey before any I/O
struct CachedFlightsDataSource: FlightsDataSource { init(wrapping: FlightsDataSource, directory: URL, ttl: TimeInterval, now: @Sendable () -> Date) } // only caches 2xx
struct FixtureFlightsDataSource: FlightsDataSource { init(bundle: Bundle, name: String, delay: Duration) }
```
`JSONDecoder` isn't `Sendable`, so the service creates its decoder inside `searchFlights` (it's cheap) instead of storing a shared one. This avoids a Swift 6 warning.

`enum FlightSearchError: Error, Equatable { case offline, timeout, missingAPIKey, unauthorized, rateLimited, server(status: Int, message: String?), decoding, unknown }`

### 3.5 View
```swift
final class FlightResultsViewController: UIViewController {
    init(viewModel: FlightResultsViewModel, imageLoader: ImageLoading)
    // viewDidLoad: build pinned header views + collection view, bind:
    //   viewModel.onStateChange = { [weak self] in self?.render($0) }
    //   render(viewModel.state); viewModel.start()
}
```
- One `UICollectionView` with a `UICollectionViewCompositionalLayout` and a `UICollectionViewDiffableDataSource<Section, Item>`.
- `Section`: `.loadingBanner`, `.listTop`, `.promotions`, `.listBottom`
- `Item`: `.loadingBanner`, `.skeleton(Int)`, `.flight(id: String)`, `.promotion(id: String)`
  - ⚠ Items carry **ids only**; the VC looks up the current `FlightCardViewData` by id in a dictionary built during `render`. This is Apple's recommended pattern.
  - **Why not put the ViewData in the item?** Diffable identity is the whole `Hashable` value, so any content change would look like delete + insert (no move animation on re-sort). The alternative, overriding `==` to compare ids only, would make `FlightResultsState` equality lie in the ViewModel tests.
  - Content changes for an existing id are applied with `reconfigureItems`.
- `.promotions` section: `orthogonalScrollingBehavior = .groupPaging` (leading-aligned with the cards).
- Empty and error views are the collection view's `backgroundView`, with an empty snapshot.
- The View calls **only** ViewModel intents. It never touches the Coordinator.

## 4. Dependency injection & composition root

`AppEnvironment` (built once in `SceneDelegate`):
```swift
@MainActor
struct AppEnvironment {
    let flightSearchService: FlightSearchService
    let searchRequest: FlightSearchRequest
    let dummyContent: DummyContentProvider
    let imageLoader: ImageLoading
    static func make(processInfo: ProcessInfo = .processInfo, config: AppConfig = .fromBundle(), now: Date = .now) -> AppEnvironment
}
```
**Unit-test guard:** the test target runs inside the app, so the app launches before the tests run. If `ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil`, `SceneDelegate` shows a plain empty root view controller and **does not start any coordinator**. This way tests never trigger a live SerpApi search or use quota. The check lives in `AppEnvironment.isRunningUnitTests`, next to the other process-info reads.

Selection logic (the only place `#if DEBUG` and launch arguments are read):
```
#if DEBUG
if forceState = arg("-FRForceState") → StubFlightSearchService(mode)
else if arg("-FRDataSource") == "fixture" → SerpApi service over FixtureFlightsDataSource; request date = fixture date
else → SerpApi service over CachedFlightsDataSource(Remote)
#else
→ SerpApi service over RemoteFlightsDataSource
#endif
```

## 5. Concurrency (Swift 6)

| Type | Isolation |
|---|---|
| ViewModel, VC, views, coordinators, `AppEnvironment` | `@MainActor` |
| Services, data sources, HTTP client, mapper, formatters, sorter | `Sendable` value types or `final class: Sendable` with only immutable state; `nonisolated` |
| `ImageLoader` | `actor`, or `@MainActor` with an internal `NSCache` (decided in the build step, but it must compile warning-free) |
| `CachedFlightsDataSource` | File I/O inside `async` functions. No shared mutable state, so it can be a struct. |

Rule: **the project must compile with zero warnings** under Swift 6 mode. Silencing warnings with `@unchecked Sendable` or `nonisolated(unsafe)` requires a comment explaining why, and gets noted in NOTES.md.

## 6. Logging
`Log` wraps `os.Logger` (subsystem = bundle id, categories `network`, `mapping`, `navigation`). Any URL passes through `redact(url:)`, which replaces the `api_key` value with `***`. `print` isn't used.

## 7. Testability matrix

| Unit under test | Collaborators replaced with | Needs UIKit? |
|---|---|---|
| `FlightOfferMapper` | none (DTO fixtures) | No |
| DTO / `FlightOffer` `Codable` | none (strict-decoding fixtures, round-trip) | No |
| `SerpApiFlightSearchService` | `MockFlightsDataSource` returning `(data, status)` or throwing `URLError` | No |
| `SerpApiRequestBuilder` | none | No |
| `RemoteFlightsDataSource` | `MockHTTPClient` (captures the `URLRequest`) | No |
| `CachedFlightsDataSource` | temp directory + fake clock + counting inner source | No |
| `FlightResultsViewModel` | `MockFlightSearchService` (configurable result, controllable suspension) + `SpyCoordinatorDelegate` | **No** |
| `FlightOfferSorter` | none | No |
| Formatters | none | No |

The test target doesn't import UIKit anywhere. `@testable import FlightResults` loads the app module, but no test file refers to a UIKit type.

To test the `loading` state *during* a request, `MockFlightSearchService` suspends on a `CheckedContinuation` held by the test. The test starts `load()` in a `Task`, checks `state == .loading`, resumes the continuation, awaits the task, then checks the final state.
