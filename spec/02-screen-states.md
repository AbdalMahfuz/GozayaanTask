# 02 — Screen States

## 1. State type

```swift
enum FlightResultsState: Equatable {
    case loading
    case success([FlightCardViewData])   // non-empty, already sorted
    case empty(EmptyStateViewData)
    case error(ErrorStateViewData)
}
```

Rules:
- `success` **always** holds at least 1 item. Zero items is `empty`. The View never has to check for an empty array.
- The **initial** state is `.loading`, so the very first frame shows skeletons and nothing blank ever flashes.
- `state` is `private(set)` and only changes on the main actor.
- Each assignment to `state` calls `onStateChange` exactly once, **including** a re-sort inside `success` (same case, new order).

## 2. What is on screen in each state

Pinned area: **H** = route header, **D** = date strip, **S** = sort/filter bar. These are always visible in every state.

| Region | loading | success | empty | error |
|---|---|---|---|---|
| H route header | ✅ | ✅ | ✅ | ✅ |
| D date chips | dates + **shimmer bars** instead of fares; chart button grey border | dates + dummy fares; selected chip yellow; chart button yellow border | same as success | same as success |
| S sort + filter | enabled (choice is saved for later) | enabled; reorders the list | **disabled** (50% alpha) | **disabled** (50% alpha) |
| Progress bar + "Hang tight!" text | ✅ | – | – | – |
| Skeleton cards (shimmer) | 3 | – | – | – |
| Flight cards | – | ✅ all offers | – | – |
| Promo carousel | after skeleton #2 | after card #2 (or after the last card if count < 2) | – | – |
| Empty view | – | – | ✅ | – |
| Error view + Try Again | – | – | – | ✅ |

### 2.1 Loading
- Progress bar: white track with an orange fill. The fill animates 0 → 90 % with ease-out over ~8 s, then waits there. It is a **fake, non-blocking progress indicator**: SerpApi gives no progress events, and the brief/design only need a sense of progress.
- Title: `Hang tight! We’re finding the best flight options for you.` (uses a typographic apostrophe).
- The shimmer runs on all skeleton blocks and on the date-strip fare bars.
- When Reduce Motion is on, the shimmer is replaced by a static placeholder and the progress bar doesn't animate.

### 2.2 Success
- Cards follow the ViewModel's order. When the sort changes, cards **move in place** with animation: a diffable snapshot keyed by `FlightOffer.id`, with no reload flash and no jump to the top.
- The list scrolls to the top only when *new* results arrive, for example after Retry. It doesn't scroll on re-sort.

### 2.3 Empty
Shown centred in the content area:
- Icon: SF Symbol `airplane.departure`, 48 pt, colour `brandBlue`.
- Title: `No flights found`
- Message: `We couldn’t find any flights from {DAC} to {JFK} on {15 Oct, 2026}. Try a different date.`
- No button (D-26).

### 2.4 Error
Shown centred in the content area:
- Icon: `wifi.slash` for offline or timeout, otherwise `exclamationmark.triangle`.
- Title and message: from the table in §4.
- Button: **Try Again** calls `viewModel.retry()`, which sets state to loading and runs the search again.
- DEBUG builds only: a small, lighter line below the message with technical detail (for example `HTTP 401: Invalid API key`). It is never shown in Release.

## 3. Transitions

```
            ┌──────────────── retry() ─────────────────┐
            ▼                                          │
 init ─► loading ──► success ──(sort)──► success       │
            │  └───► empty                             │
            └──────► error ────────────────────────────┘
```

| From | Event | To | Notes |
|---|---|---|---|
| (init) | ViewModel created | `loading` | Initial value. Nothing is emitted until the VC binds. |
| `loading` | service returns ≥1 displayable offer | `success(sorted)` | |
| `loading` | service returns 0 offers, or all were skipped | `empty` | |
| `loading` | service throws `FlightSearchError` | `error` | Mapped as in §4 |
| `loading` | task cancelled (VC deallocated or retry replaced it) | *(no change)* | `CancellationError` / `URLError.cancelled` are ignored |
| `success` | `selectSort(x)` where x ≠ current | `success(resorted)` | Same offers, new order |
| `success` | `selectSort(x)` where x == current | *(no change, no emit)* | |
| `loading` / `empty` / `error` | `selectSort(x)` | *(state unchanged)* | `sortOption` is stored and applied to the next success |
| `error` | `retry()` | `loading` → … | |
| `loading` | `load()` or `retry()` called again | *(ignored)* | Only one search runs at a time |
| `success` / `empty` | `load()` called | `loading` → … | Allowed (used for re-running the search); not exposed in the UI |

### Stale responses
Each search gets a generation counter. A result from an older generation is dropped. This prevents an old slow response from overwriting a newer one.

## 4. Error mapping (`FlightSearchError` → user text)

| `FlightSearchError` | Produced when | Icon | Title | Message |
|---|---|---|---|---|
| `.offline` | `URLError` `.notConnectedToInternet`, `.networkConnectionLost`, `.dataNotAllowed` | wifi.slash | No internet connection | Check your connection and try again. |
| `.timeout` | `URLError.timedOut` (30 s request timeout) | wifi.slash | This is taking too long | The search timed out. Please try again. |
| `.missingAPIKey` | Key absent or empty in config (request never sent) | triangle | Search unavailable | Flight search isn’t configured. *(DEBUG: “Add SERPAPI_API_KEY to Config/Secrets.xcconfig”)* |
| `.unauthorized` | HTTP 401/403 | triangle | Search unavailable | We couldn’t connect to flight search. Please try again later. |
| `.rateLimited` | HTTP 429, or error text containing “run out of searches” | triangle | Too many searches | Please wait a moment and try again. |
| `.server(status:message:)` | Other non-2xx, or HTTP 200 with an `error` that isn’t a no-results message | triangle | Something went wrong | We couldn’t load flights right now. Please try again. |
| `.decoding` | Top-level JSON can’t be decoded | triangle | Something went wrong | *(same as above)* |
| `.unknown` | Anything else | triangle | Something went wrong | *(same as above)* |

### Empty is not an error
SerpApi returns **HTTP 200 with `"error": "Google Flights hasn't returned any results for this query."`** when there are no flights. This is mapped to **empty** (an empty offer list), not to an error.
- Detection: the `error` string, lowercased, contains `"hasn't returned any results"` or `"no results"`.
- This string match is brittle, which we accept. It is isolated in one function (`SerpApiErrorClassifier`) and has a unit test with the exact message.
- Also empty: HTTP 200, no `error`, and both arrays missing or empty.

## 5. Forcing each state (for review and walkthrough)

DEBUG-only launch arguments, read **only** by the composition root (`AppEnvironment`):

| Launch argument | Result |
|---|---|
| *(none)* | Live SerpApi (with DEBUG disk cache) |
| `-FRDataSource fixture` | Bundled real JSON, 1.5 s delay → success |
| `-FRForceState loading` | Stub whose `search` never returns → loading forever |
| `-FRForceState empty` | Stub returns `[]` after 1 s → empty |
| `-FRForceState error` | Stub throws `.offline` after 1 s → error. Try Again leads to loading and then error again. |

Committed shared schemes: `FlightResults`, `FlightResults (Fixture)`, `FlightResults (Loading)`, `FlightResults (Empty)`, `FlightResults (Error)`.
