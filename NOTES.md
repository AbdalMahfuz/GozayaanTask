# NOTES

Filled in step by step while building (see `spec/07-implementation-plan.md`), not written from memory at the end.

## AI tool
- **Claude Code** (CLI). Spec and data layer were built with Claude Sonnet 5; I switched to Claude Opus 5 partway through the UI steps and for the verification pass.

## How I directed the AI
- **Option A:** the spec in `/spec` came first. The AI drafted it from the brief and the given design PNGs; I reviewed it and changed the decisions listed below before any code was written.
- Development follows the plan in `spec/07-implementation-plan.md`: one focused prompt per step, then build, test, my review and a commit.

## Corrections log
What the AI produced, what was wrong with it, and what I changed.

| # | Step | AI output | Problem | Correction | Caught by |
|---|---|---|---|---|---|
| 1 | Spec | Added a decorative **Edit** button, because the brief mentions one | The design has no Edit button, and UI is judged against the design | Removed (D-19) — later reversed, see #14 | me |
| 2 | Spec | `FlightOffer` not `Codable`; lossy decoding that silently dropped broken groups | The brief asks for Codable models; silently hiding bad data makes problems invisible | All models `Codable`; strict decoding, so a decoding failure shows the error state (D-32) | me |
| 3 | Spec | 1 adult, to avoid the question of whether the price is per person | The design shows 2 passengers | 2 adults, price treated as the total; to be verified against the real response (D-05) | me |
| 4 | Spec | Planned to crop the promo artwork (including bank logos) from the design into the app | The repo will be public | Own placeholder artwork (D-30) | AI flagged it once I said the repo will be public; I accepted |
| 5 | Spec | Xcode project at the root of the workspace, next to the brief PDF and design files | Task material could be pushed by accident | The repo is its own `FlightResults/` folder; the PDF and design stay outside it | me |
| 6 | Spec | Response structs designed from the SerpApi docs, from memory | With strict decoding, a single wrong required field would break the live app | Capture a real response first (plan Step 2) | AI, when I asked it to check the spec for gaps |
| 7 | Spec | Planned `static` shared date/number formatters | Rejected by Swift 6 strict concurrency (non-`Sendable` static) | One formatter per instance (A11) | AI, when I asked it to check the spec for gaps |
| 8 | Spec | Unit tests hosted in the app with no guard | Every test run would launch a live SerpApi search | Unit-test guard in `SceneDelegate` (A10) | AI, when I asked it to check the spec for gaps |
| 9 | Spec | Minimum iOS 16 | No iOS 16 simulator on this Mac, so it could never be tested | iOS 18 (D-01) | AI, when I asked it to check the spec for gaps |
| 10 | Code (Step 2) | Spec planned `currency=BDT`. First fix: the AI proposed switching the **whole app** to USD (request, display, dummy fares) | A live request with `currency=BDT` returned HTTP 400 `"Unsupported \`BDT\` for currency."`, confirmed by SerpApi's own currency list — but I want the design's BDT labelling kept, since that's GoZayaan's market | Kept `BDT` as the app's business/display currency; only the wire request to SerpApi is hardcoded to `USD` (`SerpApiRequestBuilder.wireCurrencyCode`); `SerpApiFlightSearchService` converts the returned price with a fixed rate (`× 122`) before it reaches the ViewModel (D-06) | me — I rejected the AI's first "just use USD everywhere" fix and asked for BDT with a conversion instead. Re-checked on 2026-09-16: `currency=BDT` still returns HTTP 400, and SerpApi's published Google Travel currency list (106 entries) has no BDT (INR and PKR are there), so asking for BDT isn't an option; keeping USD-on-the-wire with a fixed rate |
| 11 | Code (Step 2) | D-05 flagged price-per-person as an open risk | Same search with `adults=1` vs `adults=2` returned `price_insights.lowest_price` 574 vs 1148 — exactly double | Confirms `price` is already the correct total; no code change (D-05 marked ✔ Verified) | AI, running the real Step 2 captures |
| 12 | Code (Steps 13) | `EmptyStateView`/`ErrorStateView` positioned the icon at "25% of the collection's height" (05 §3.5) with `NSLayoutConstraint(item: icon, attribute: .top, ..., toItem: self, attribute: .height, multiplier: 0.25, ...)` | Crashed on launch: `NSInvalidArgumentException: Invalid pairing of layout attributes` — Auto Layout only allows relating same-family attributes (size-to-size, position-to-position), never a position (`.top`) to a size (`.height`) directly, no matter the value being numerically sensible | Replaced with a standard invisible spacer view whose own height is `self.height × 0.25` (a valid height-to-height constraint across the two views), then anchored the icon below that spacer | me — ran the `(Empty)` scheme, hit the crash, pasted the stack trace |
| 13 | Code (Step 12) | `LoadingBannerCell` started the progress fill, and `SkeletonCardCell` built its shimmer mask, from subview sizes read in the **cell's** `layoutSubviews` | Those subviews live in `contentView`, whose own layout pass runs later, so their sizes were still zero: the orange fill never appeared and the mask was empty, so skeletons never shimmered. A still screenshot looked fine, which is why the AI first reported the loading state as correct | Progress bar moved into a frame-based `ProgressBarView` that sizes itself in its own `layoutSubviews`; skeleton mask built once from the spec's fixed block geometry. Verified by measuring the orange width over time and pixel-diffing consecutive screenshots | AI, during Step 15 verification (comparing against the loading design frame) |
| 14 | Spec + code (Step 15) | The header had no Edit button, per my own earlier call in #1 | The brief lists Edit as part of the route header ("origin → destination, the date, passenger count, 'One Way', and an **Edit** button"), so leaving it out drops a stated requirement; the design frame simply omits it | Decorative Edit button added to `RouteHeaderView`, trailing side, no target — like the back chevron, Filter and chart button. D-19 rewritten as a reversal, with `00`, `05 §2.1` and G5 updated | me — I reversed my own earlier decision after re-reading the brief |
| 15 | Code + spec (Step 15) | Promo carousel used `.groupPagingCentered`, so the first promo sat centred with dead space to its left while the flight cards started at 16 pt | The carousel looked detached from the list it sits inside; the design's own frames are inconsistent here (the loading frame clips the row at 16 pt, the success frame runs it full-bleed) | Switched to `.groupPaging` so the first promo's leading edge lines up with the cards; spec `04`, `05 §3.2` and G8 updated | me |
| 16 | Spec + code (Step 15) | Spec 05 §1.2's type scale, which the AI claimed to have "measured from the PNGs" | Measuring glyph heights in the design export showed the whole scale was 15–30 % too large (header 22 vs 20, chip price 17 vs 14, sort/filter 16 vs 12, card price 20 vs 16). It made fares in the date strip collide and forced the promo title onto one truncated line | I took the real values from the Figma file and reset the Theme tokens; spec 05 §1.1–1.3, §2.2, §2.3 and §3.3 updated to match the code | me — I compared the running app against the Figma frames |
| 17 | Tests (Step 15) | A new `RetainCycleTests` file, reported as passing | It ran **zero tests**: the AI had written the file outside the repo, so it was never in the test target, and `xcodebuild` still printed "TEST SUCCEEDED". The original A7 test was also weak — it released a bare ViewModel with no VC, no closures and nothing in flight, so it could never catch the cycle that matters | File moved into the target; the test now builds the real graph (VC + VM + delegate, cells rendered, and a second case with a search in flight). Both are mutation-checked: temporarily making `onStateChange` capture `self` strongly makes them fail, which is how the empty run was noticed in the first place | AI, running a deliberate-leak mutation to check the test could fail |
| 18 | ViewModel + tests (Step 15) | `start()` ran the search as `Task { [weak self] in guard let self else { return }; await self.load() }`, and #17's "search in flight" test passed | `guard let self` holds a strong reference **across the `await`**, so the task kept the ViewModel alive until the request finished — `deinit`, which is what cancels the task, could never run first. Leaving the screen mid-search cancelled nothing. #17's in-flight test missed it because it released the screen before the task had even called the service: it never had a search in flight | Load split into synchronous `beginLoad` / `finishLoad`; the task holds only the service and request while waiting and reaches back with `self?` afterwards. New `test_releasingViewModel_cancelsInFlightSearch`; the retain-cycle test now waits until the service is actually called; the mock is cancellation-aware like `URLSession`. Both tests fail against the old `start()` and pass against the new one | AI, during a full code review requested by me — spotted by reading `start()` beside `deinit`, then proven with a test that waits for the search to really be in flight |
| 19 | Data layer (Step 15) | Force unwraps in `FlightOfferMapper` (date components, `calendar.date(from:)!`), `SerpApiRequestBuilder` (`URLComponents(...)!`, `components.url!`, date components) and three `TimeZone(identifier: "UTC")!` | Rule R6 bans force unwraps outside tests, and the Step 5 review checklist specifically says "no force unwraps building the `URL`". All were safe in practice, but a crash is the wrong failure mode for a network call | `calendar.component(_:from:)` and `startOfDay(for:)` (non-optional) replace the unwrapped components; `buildURLRequest` now `throws` `.unknown` instead of trapping; `.gmt` replaces the UTC lookups; the fixture date is a constant. Only literal constant URLs keep `!`. Mapper and time-zone tests unchanged and green | AI, during the same review |

## `@unchecked Sendable` uses
Spec 04 §5 requires each one to be explained in code and listed here. There is no `nonisolated(unsafe)` anywhere.

| Type | Why it's safe |
|---|---|
| `FlightOfferMapper` | Holds one `DateFormatter` (not `Sendable`), configured in `init` and never mutated; only read afterwards |
| `PriceFormatter` | Same, with a `NumberFormatter` |
| `HeaderDateFormatter`, `ChipDateFormatter` | Same, with a `DateFormatter` |
| `CancellableTaskBox` (ViewModel) | `set` runs only on the main actor; `cancel` runs only from the ViewModel's `deinit`, which can't overlap a `set`; `Task.cancel()` is thread-safe |

## Thrown away
- An early `serpapi_dac_jfk_oneway.json` fixture, hand-written from the SerpApi docs (before the real key arrived) to unblock Step 3–6 work while waiting for the key (the user said not to let the key block progress). Replaced wholesale by the real captured response once the key was available, per D-32/D-11's own reasoning about not trusting docs-from-memory shapes.

## Decisions that were mine
- Reviewed and confirmed or changed: D-01, D-03, D-05, D-18, D-19, D-27, D-30, D-32 (see `spec/01-decisions.md`).
- Repo layout, commit identity, and no AI attribution lines in commits (AI use is disclosed here instead).

## Walkthrough talking points (Edit + BDT)

### Edit button (D-19)
**One-liner:** The brief names Edit in the route header and says it can be decorative, so it ships as a trailing header control with no target — same pattern as back, Filter, and the chart button. The design frame omits it; I followed the brief’s explicit list over the frame.

**If they push on design vs brief:** First I dropped Edit to match the PNG (corrections log #1). On re-read, the brief’s required header elements won, so I reversed that (corrections log #14). That sequence is intentional judgment, not an oversight.

### BDT / USD (D-06)
**One-liner:** The UI stays in BDT for GoZayaan’s market; SerpApi rejects `currency=BDT` (HTTP 400, and BDT isn’t on their Google Travel currency list), so the wire request is fixed to USD and prices are converted with a documented fixed rate (`× 122`) in the service layer before the ViewModel.

**If they ask “why not just show USD?”:** That would match the API, but it would break the design’s BDT labelling. I rejected the AI’s “switch everything to USD” fix and kept display currency separate from wire currency.

**Known limitation to volunteer:** The rate is a snapshot, not live FX. Production would proxy through a GoZayaan backend or a real FX feed.
