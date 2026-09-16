# NOTES

Filled in step by step while building (see `spec/07-implementation-plan.md`), not written from memory at the end.

## AI tool
- **Claude Code** (CLI), model Claude Opus 5.

## How I directed the AI
- **Option A:** the spec in `/spec` came first. The AI drafted it from the brief and the design PNGs; I reviewed it and changed the decisions listed below before any code was written.
- Development follows the plan in `spec/07-implementation-plan.md`: one focused prompt per step, then build, test, my review and a commit.

## Corrections log
What the AI produced, what was wrong with it, and what I changed.

| # | Step | AI output | Problem | Correction | Caught by |
|---|---|---|---|---|---|
| 1 | Spec | Added a decorative **Edit** button, because the brief mentions one | The design has no Edit button, and UI is judged against the design | Removed (D-19) | me |
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
