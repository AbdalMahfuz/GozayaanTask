# 07 — Implementation Plan

## Working agreement (how the AI is directed)
- **One step = one focused prompt = one commit or more.** No "build the whole app" prompt.
- Each prompt names: the spec sections it implements, the files allowed to change, and the acceptance-criteria IDs that must pass.
- After each step: **build (0 warnings) → run tests → human review against the step checklist → commit**.
- Anything the AI got wrong and we corrected goes straight into the **NOTES.md → Corrections log**: what it wrote, why it was wrong, what we changed. Write it down immediately; it can't be reconstructed reliably later.
- If an AI change touches a file outside the step's list, revert that part and re-prompt.
- Commit messages: `<area>: <imperative summary>`, e.g. `data: map SerpApi groups to FlightOffer`.

---

## Step 0 — Repo & spec
- `.gitignore` (Xcode, `DerivedData`, `*.xcuserstate`, `Config/Secrets.xcconfig`, `.DS_Store`, **`/design/` and `*.pdf`**: task material stays local because the repo will be public)
- Commit `/spec` **before any code**, so the history shows the spec came first.
- Commit: `docs: add technical spec`

## Step 1 — Project skeleton & composition root
**Implements:** `04 §2, §3.1, §4` (skeleton only)
- Xcode project `FlightResults` (iOS 16, Swift 6 mode, iPhone portrait, light style), unit-test target `FlightResultsTests`.
- Remove Main.storyboard; `SceneDelegate` creates the window → `AppCoordinator` → `FlightResultsCoordinator` → placeholder navy VC.
- `Config/Base.xcconfig` with `#include? "Secrets.xcconfig"`, `Secrets.example.xcconfig`, Info.plist `SERPAPI_API_KEY = $(SERPAPI_API_KEY)`, `AppConfig`.
- Folder structure created as in `04 §2`.

**Review:** coordinators retained through `childCoordinators`; no storyboard reference left in Info.plist; builds with no `Secrets.xcconfig`; 0 warnings.
**AC:** A9, G17 (partly)
**Commit:** `app: set up UIKit project with AppCoordinator and config`

## Step 2 — Models, DTOs, decoding helpers
**Implements:** `03 §1.1, §2, §3`
- `FlightSearchRequest`, `FlightOffer`, `FlightEndpoint`, `LocalDateTime`, `Promotion`, `DateFare`, `SortOption`
- DTOs and domain models, all `Codable` (D-32); `JSONDecoder.serpApi` (snake_case)
- Tests: `DecodingTests`: strict failures (missing key, type mismatch) and domain model round-trips

**Review:** snake_case strategy doesn't clash with explicit `CodingKeys`; no lossy or `try?` decoding sneaking in (the AI often adds it "for robustness", but D-32 says a decoding failure must show the error state); optionals only where SerpApi really omits the field; no `Date` used for API times.
**AC:** B8, B10, B13
**Commit:** `model: add Codable domain models and SerpApi DTOs`

## Step 3 — Mapper (the core of the data layer)
**Implements:** `03 §4`, fixtures `03 §8` (mapping ones)
- `FlightOfferMapper` (pure), time parsing, day offset, id, dedupe
- `FlightOfferMapperTests` + JSON fixtures

**Review:** stops come from legs, not `layovers.count`; departure is the **first** leg and arrival the **last** leg (AI often uses the first leg for both); `DateFormatter` is static, `en_US_POSIX`, UTC; day offset uses calendar days, not `hours / 24`; invalid groups are skipped, not thrown.
**AC:** B3–B7, B9, B11, B12
**Commit:** `data: flatten SerpApi flight groups into FlightOffer`

## Step 4 — Networking, service, errors, cache
**Implements:** `03 §1.2, §4.8`, `02 §4`, `04 §3.4, §6`
- `HTTPClient` + `URLSessionHTTPClient`, `SerpApiRequestBuilder`, `RemoteFlightsDataSource`, `SerpApiErrorClassifier`, `FlightSearchError`, `SerpApiFlightSearchService`, `CachedFlightsDataSource`, `Log` + redaction
- Tests for all of the above using `MockHTTPClient` / mock data source. **No test hits the network.**

**Review:** HTTP 200 + "no results" → `[]`; status checked **before** decoding; `api_key` absent from cache key and logs; `URLError.cancelled` not reported as an error; missing key throws before any request; no force unwraps building the `URL`.
**AC:** B1, B2, C1–C10
**Commit(s):** `data: add SerpApi request builder and HTTP client`, `data: add flight search service with error classification`, `data: add debug response cache`

## Step 5 — Capture real fixture
- With the key: run one live search (DAC→JFK, 2 adults). Compare one price with Google Flights for 2 adults to confirm SerpApi's price is the total (D-05) and write the result in NOTES.md.
- Save the JSON response to `Resources/Fixtures/serpapi_dac_jfk_oneway.json`. **Strip `api_key`** from `search_metadata` / `search_parameters` URLs.
- `FixtureFlightsDataSource`, `StubFlightSearchService`, `DummyContentProvider`, `AppEnvironment.make` selection logic, 5 shared schemes.
- Sanity test: the bundled fixture maps to ≥ 1 offer and includes at least one 1-stop or 2-stop offer.

**Review:** `grep` the fixture for the key; launch args read only in `AppEnvironment`.
**AC:** A8, H2
**Commit:** `app: add fixture/stub data sources and state-forcing schemes`

## Step 6 — Formatters & ViewModel
**Implements:** `03 §5, §6, §7`, `02 §1, §3, §4`, `04 §3.2, §3.3`
- Formatters + `FormatterTests`
- `FlightOfferSorter` + tests
- `FlightResultsState`, ViewData types, `FlightResultsCoordinatorDelegate`, `FlightResultsViewModel`
- `MockFlightSearchService` (result + continuation mode), `SpyCoordinatorDelegate`, `FlightOffer.fake(...)`
- `FlightResultsViewModelTests`

**Review:** `import Foundation` only; `@MainActor`; `weak` delegate; re-entry guard + generation check; cancellation not turned into error; `onStateChange` fires exactly once per change; sort isn't done in the View; `sorted(by:)` made stable; `NumberFormatter` grouping is actually on under `en_US_POSIX` (test F1 proves it).
**AC:** A1–A3, A6, A7, D1–D12, E1–E9, F1–F5
**Commits:** `formatting: add price, duration and date formatters`, `viewmodel: add sorting`, `viewmodel: add FlightResultsViewModel with state machine`

## Step 7 — Coordinator navigation
**Implements:** `04 §3.1`, D-18, D-23
- `FlightResultsCoordinator` builds VM + VC, conforms to the delegate, opens `SFSafariViewController` for http(s) only, logs flight selection.

**Review:** no strong VM → Coordinator reference; Safari presented from `navigationController`; nothing navigation-related added to the VM.
**AC:** A4, A5, G9 (after UI exists)
**Commit:** `coordinator: open promotions in Safari view controller`

## Step 8 — Theme & pinned header area
**Implements:** `05 §1, §2.1–2.3`
- `Theme` (colors, typography, spacing), `RouteHeaderView`, `DateFareStripView` + chip cell, `SortFilterBarView` (button only, no dropdown yet)
- VC root layout: pinned header stack + empty collection view below.

**Review:** hex values match `05 §1.1` exactly; selected chip scrolled to centre; back/chart/Filter present and decorative, no Edit button; Auto Layout without ambiguity warnings in the console.
**AC:** G5, G6, G7
**Commit:** `ui: add route header, date fare strip and sort/filter bar`

## Step 9 — Flight card
**Implements:** `05 §3.1`
- `FlightCardCell`, `FlightTimelineView`, `DashedLineView`, `ImageLoader`
- Collection view + diffable data source (success state only), rendering fixture data.

**Review:** `+1Day` superscript alignment and code alignment under time; truncation priority for airline name; `prepareForReuse` cancels image load; ids-only items (`04 §3.5`); no formatting inside the cell.
**AC:** G2, G11, G12, G15
**Commit:** `ui: add flight card cell and results list`

## Step 10 — Promo carousel
**Implements:** `05 §3.2`, D-22
- Own `promo_discount` artwork (D-30, not cropped from the design), `PromoCardCell`, orthogonal section, section placement logic (after card 2 / fewer than 2 cards), tap → VM intent.

**Review:** placement with 0, 1, 2, 5 offers; paging centred; Safari opens.
**AC:** G8, G9
**Commit:** `ui: add discount carousel between flight cards`

## Step 11 — Loading state
**Implements:** `05 §3.3, §3.4, §4`, `02 §2.1`
- `ShimmerView`, `SkeletonCardCell`, `LoadingBannerCell` (progress bar), strip fare shimmer, chart border colour per state.

**Review:** shimmer restarts after reuse and foregrounding; Reduce Motion path; skeletons not focusable by VoiceOver; no timers leaking after leaving the loading state.
**AC:** G1, G13, G14
**Commit:** `ui: add loading skeletons with shimmer and progress banner`

## Step 12 — Empty & error states
**Implements:** `05 §3.5`, `02 §2.3, §2.4`
- `EmptyStateView`, `ErrorStateView`, backgroundView switching, sort-button disabling, Try Again → retry.

**AC:** G3, G4, G17
**Commit:** `ui: add empty and error states with retry`

## Step 13 — Sort dropdown
**Implements:** `05 §2.4`, `02 §2.2`
- `SortDropdownView` overlay, chevron animation, `selectSort`, in-place animated re-sort.

**Review:** no scroll jump; outside tap dismisses; VoiceOver modal; title updates from `onSortOptionChange`.
**AC:** G10
**Commit:** `ui: add sort dropdown with in-place reordering`

## Step 14 — Verification & polish
- Run the entire `06` checklist. Capture screenshots of the 4 states + sort into `docs/screenshots/`.
- Live run with the real key (G16), iOS 18 run, small/large screen (G18).
- Memory graph check (A7). Grep checks (A1–A5, A8, H2).
- Fix findings as separate small commits.
**Commit:** `chore: verification fixes` (as needed)

## Step 15 — README & NOTES
- `README.md`: setup (key), schemes, tests command, architecture diagram (from `04 §1`), known limitations.
- `NOTES.md`: AI tool (Claude Code + model), how it was directed (spec → step prompts), **Corrections log** (accumulated), code thrown away, decisions that were mine (cross-reference the ✔ Reviewed items and D-numbers in `01`), what I'd do with more time.
**AC:** H1–H6
**Commit:** `docs: add README and NOTES`

---

## General AI-output review checklist (apply at every step)
| # | Look for | Why it matters |
|---|---|---|
| R1 | `import UIKit` sneaking into ViewModel/Model/Data | Breaks the core architecture rule |
| R2 | `[weak self]` missing in stored closures (`onStateChange`, image loader completion) | Retain cycles |
| R3 | Strong delegate, or VC holding the Coordinator | Retain cycle / boundary violation |
| R4 | `DateFormatter`/`NumberFormatter` created per call or per cell | Performance |
| R5 | Locale/time-zone dependent parsing (no `en_US_POSIX`, device TZ) | Wrong times, flaky tests |
| R6 | Force unwraps (`!`, `try!`) outside tests | Crashes on unexpected data |
| R7 | UI updates off the main actor; `DispatchQueue.main.async` sprinkled instead of actor isolation | Races; Swift 6 violations |
| R8 | `@unchecked Sendable` / `nonisolated(unsafe)` added just to silence the compiler | Hides real races |
| R9 | Diffable duplicate identifiers or whole-model item identity | Crash / no move animation |
| R10 | Reused cells showing stale image or stale shimmer | Visible bugs while scrolling |
| R11 | Sorting or formatting inside `cellForItem` / views | Brief explicitly forbids |
| R12 | Tests that hit the real network or depend on the current date | Flaky, burns API quota |
| R13 | API key in source, logs, fixture or commit | Security |
| R14 | Swallowed errors (`try?` hiding failures that should become `.error`) | Wrong state shown |
| R15 | Over-engineering: generic "BaseViewModel", DI containers, reactive libs | Not needed; harder to explain on the call |
| R16 | Spec drift: behaviour that differs from `02`/`03` without a decision recorded | Either fix code or record a new D-number |
