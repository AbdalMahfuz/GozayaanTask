# 01 — Decisions Log

The brief says: *"Some things are left open on purpose… decide for yourself and tell us why."*
Every such point is listed here with its decision and reasoning.
**✔ Reviewed (2026-09-14)** marks decisions confirmed or changed in the spec review. **↻ May change** marks decisions the reviewer may revisit later.

---

## Platform & project

### D-01 — UIKit, all in code, iOS 16+, Swift 6 language mode
- **Why UIKit:** the Coordinator pattern fits UIKit naturally, because `UINavigationController` is a real object the Coordinator owns and pushes or presents on. In SwiftUI, a Coordinator usually ends up wrapping `NavigationStack` state, which weakens the boundary the brief scores.
- **Why no storyboards:** dependencies go in through initializers, and diffs stay reviewable.
- **Why iOS 16:** it covers async/await, `UICollectionViewCompositionalLayout`, diffable data sources and `UIButton.Configuration`, with no availability checks. Close to every device in use supports it.
- **Why Swift 6 mode:** the compiler catches data races (a ViewModel updating UI off the main thread, services that aren't `Sendable`). That is a class of AI-written bug we want caught at build time.

### D-02 — No third-party dependencies
Shimmer, image loading and JSON decoding are small enough to write ourselves. That removes supply-chain and version risk, and every line can be explained on the call.

---

## Search parameters

### D-03 — Route: **DAC → JFK** (Dhaka → New York) ✔ Reviewed
- It matches the design header ("Dhaka - New York"), and the cards show 1-stop and 2-stop itineraries.
- DAC→BKK (the brief's example) is mostly non-stop, so the 1 Stop / 2 Stop mapping would rarely be exercised with real data. DAC→JFK has no non-stop flights, so real results show 1 and 2 stops.
- City names are not reliably in the API (only airport names are), so the display names `Dhaka` and `New York` are part of `FlightSearchRequest`.

### D-04 — Date: **today + 30 days**, computed at launch
- A hard-coded date goes stale: a reviewer running the app after that date gets an error or empty results from SerpApi (past dates are rejected).
- "Today" comes from an injected `DateProvider`, so tests are deterministic.
- In **fixture mode** the request date is the fixture's own date, so the header stays consistent with the data shown.

### D-05 — Passengers: **2 adults**, shown as `02`; price treated as the **total** for all passengers ✔ Reviewed ↻ May change
- Matches the design (`👤 02`).
- SerpApi's `price` is treated as the **total fare for all passengers** and shown as-is under "Starting from". It is **not** divided per person.
- Risk accepted: if SerpApi turns out to return a per-person fare, the displayed number would be half the real total. Check this against Google Flights once the real fixture is captured (Step 5) and note the result in NOTES.md.
- `adults` is a single value in `FlightSearchRequest` (built in `AppEnvironment`), so changing it later is a one-line change; the header, request and tests all read from it.

### D-06 — Fixed query: `type=2` (one-way), `currency=BDT`, `hl=en`, `gl=bd`, `adults=2`
`gl=bd` asks for Bangladesh-market results and pricing, which matches GoZayaan's market and the BDT currency.

---

## Secrets & data sources

### D-07 — API key lives in a git-ignored `Secrets.xcconfig`, passed through Info.plist
- `Config/Secrets.xcconfig` (git-ignored) defines `SERPAPI_API_KEY = …`. `Config/Secrets.example.xcconfig` is committed with a placeholder.
- The build setting is copied into Info.plist as `SERPAPI_API_KEY` and read once by `AppConfig`.
- The key is **never logged**. URLs are redacted before any debug print.
- **Known limitation, to state on the call:** any key shipped inside an app binary can be extracted. In production this call would go through a GoZayaan backend proxy. That is acceptable for a take-home and noted in the README.
- A missing or empty key is **not** silently replaced with fixture data. The app shows the error state "API key missing" (DEBUG detail included), so a wrong setup is visible.

### D-08 — Three data sources, chosen at the composition root
| Mode | How it's selected | Purpose |
|---|---|---|
| `live` | default scheme | Real SerpApi call. DEBUG builds wrap it in a **disk response cache** (TTL 6 h) to save the ~100 free searches. |
| `fixture` | scheme `FlightResults (Fixture)` → launch arg `-FRDataSource fixture` | Bundled real SerpApi JSON with a simulated 1.5 s delay. Runs with no key. Used for the walkthrough demo. |
| forced state | launch arg `-FRForceState loading\|empty\|error` (DEBUG only) | A stub service that never returns, returns `[]`, or throws, so every state can be shown on demand |

The ViewModel doesn't know which mode is active. It only sees a `FlightSearchService` protocol.

### D-09 — Cache at the raw-`Data` level, not at the `[FlightOffer]` level
Cached bytes still go through decoding and mapping, so mapping changes take effect immediately during development and no stale model shapes get stored. The cache key is the request's query items **excluding `api_key`**.

---

## Data shaping

### D-10 — Merging `best_flights` and `other_flights`
1. Concatenate: `best_flights` first, then `other_flights`, keeping API order.
2. Map each group to a `FlightOffer`. Groups that can't be displayed are **skipped** (see D-11).
3. **Remove duplicates** by `FlightOffer.id`, keeping the first occurrence (so best wins). This is required anyway because diffable data sources crash on duplicate identifiers.
4. The displayed order is then decided by the current sort (default **Cheapest**, as in the design). The sort is **stable**, so best-before-other breaks ties.
- A "Best" badge is not shown because the design has none. `FlightOffer.source` (`.best` / `.other`) is kept so a badge would be a one-line change.

### D-11 — Decoding failures are errors; valid-but-incomplete groups are skipped
Two different kinds of "bad data", handled differently:
- **The JSON doesn't match the `Codable` model** (wrong type, a required key missing, e.g. a group without `flights`): decoding throws → **error state** (`.decoding`). Nothing is silently dropped (D-32).
- **The JSON decodes, but a group can't be shown** (optional `price` absent, empty `flights` array, a time string that isn't `yyyy-MM-dd HH:mm`, no duration available): **only that group** is dropped and counted in a DEBUG log. This is valid API data, not a failure: SerpApi does leave `price` out on some results. If *every* group is dropped, the result is **empty**.

### D-12 — Times are shown as airport-local wall-clock times, never converted between time zones
SerpApi gives `"2026-02-15 12:30"` in each airport's local time, with no time-zone information. We parse it with `en_US_POSIX` in a fixed UTC calendar **only to pull out the date and time components**, then display `HH:mm` exactly as given. Converting to the device's time zone would show wrong times.
`arrivalDayOffset` = calendar days between the first leg's departure date and the last leg's arrival date. It can be negative, for example an eastward date-line crossing on other routes.

### D-13 — Stops = `legs.count - 1`
- Legs are the ground truth. `layovers[]` is used only for layover airport codes and durations.
- If `layovers.count != legs.count - 1` (inconsistent data), `legs.count - 1` still wins, and a DEBUG log is written.
- Labels copy the design exactly: `Non-Stop`, `1 Stop`, `2 Stop`, `3 Stop`. The design and brief use "2 Stop", not "2 Stops".

### D-14 — Airline label = unique airline names in leg order, joined with `" + "`
Design: "Air Arabia + US Bangla Airlin…" (truncated at the tail). The logo is the group-level `airline_logo` (SerpApi returns a "multi" logo for mixed airlines), falling back to the first leg's logo, then to a placeholder.

### D-15 — Price format: `BDT 37,400`
- The currency code, then the amount with **Western grouping** (`120,400`, not the lakh style `1,20,400`) and **no decimals**, exactly as in the design.
- The formatter uses a **fixed `en_US_POSIX` locale**, not the device locale, so a device set to Bengali doesn't show `৩৭,৪০০` and the output matches the design and tests on any machine.
- On the card, "BDT" and the amount are separate labels (different font sizes). The date strip uses one string: `BDT 70,129`.
- The amount is kept as `Int` (whole BDT, which is what SerpApi returns for BDT). A non-integer price fails decoding and leads to the error state (D-32).

### D-16 — Duration format: `4h 40m`; `5h` if minutes are 0; `45m` if hours are 0
Uses `total_duration` when present. Otherwise it is the sum of leg durations plus layover durations.

### D-17 — Date strings use a fixed English locale
Header: `15 Oct, 2026` (`dd MMM, yyyy`). Chips: `Sun 08 Feb` (`EEE dd MMM`). Month and day names are English regardless of device language, which matches the design and keeps tests deterministic.

---

## Screen behaviour

### D-18 — Flight card tap → `didSelectFlight` → the Coordinator only logs it ✔ Reviewed (best practice)
- The brief's own example protocol is `didSelectFlight(_ offer:)`, so the delegate method exists and is wired from end to end. The brief also says "Learn more" is the *only* real navigation, so the Coordinator logs the selection and does nothing else.
- The design's dropdown frame shows a **"Flight Details" link** on cards, but the main "with results" frame doesn't. We follow the main frame: **no link**, and the whole card is tappable.
- **Why this is best practice:**
  - A visible link promises a destination; one that does nothing is misleading UI (Apple HIG: controls must do what they suggest).
  - The whole card is a large, easy touch target and a single VoiceOver element (`.button`).
  - When a details screen is added, only the Coordinator changes; the View and ViewModel stay the same.

### D-19 — No "Edit" button; the header follows the design ✔ Reviewed
- The brief mentions an Edit button ("Edit can be decorative"), but the design has none. Decision: **follow the design and leave it out**.
- The back chevron is kept, as a decorative element (this is the root screen, so there is nothing to go back to).
- Be ready to explain on the call: the brief itself calls Edit optional and decorative, there's no edit flow, and "UI correctness" is judged against the design.

### D-20 — Header, date strip and sort/filter bar stay pinned; only the results scroll
The route context and the sort control stay reachable while the user scrolls a long list. The long design frame is a static render and doesn't show scroll behaviour.

### D-21 — Date strip = 7 chips from −3 to +3 days around the search date; fares hard-coded
- The brief requires hard-coded dummy fares, and they are hard-coded. Chip **dates** are generated around the search date so the selected chip always matches the header date. The design's own frames disagree (header 15 Feb, selected chip 08 Feb), and we don't copy that inconsistency.
- The selected chip (the search date, index 3) is scrolled into view on first layout.
- While **loading**, fares show as shimmer bars (as in the design). In every other state the dummy fares are shown.

### D-22 — Discount carousel position
- **Success:** a single carousel inserted **after the 2nd flight card**. With fewer than 2 offers, it goes after the last card.
- **Loading:** after the 2nd skeleton card (as in the design).
- **Empty / error:** hidden, so the state message is the only focus.
- The whole promo card is tappable, as well as the "Learn more" text, for a larger touch target. Both send the same intent.

### D-23 — Learn more opens `SFSafariViewController`, presented by the Coordinator
The user stays in the app and gets a Done button back. SafariServices is imported **only** by the Coordinator. Only `http`/`https` URLs are opened; anything else is ignored with a log.

### D-24 — Sort control = custom dropdown matching the design, not `UIMenu`
The design shows a styled white panel with a light-blue highlighted selection. `UIMenu` can't match that. The dropdown is a small overlay view; tapping outside dismisses it.
The sort choice is remembered in the ViewModel for the session and applied to whatever results arrive next (you can choose "Fastest" while loading).

### D-25 — No minimum skeleton time and no pull-to-refresh
A cached response shows immediately, with no artificial delay; the fixture mode's 1.5 s delay is only there to demo loading. Retry exists in the error state only. Pull-to-refresh isn't in the design.

### D-26 — Empty and error states designed by us (not in Figma), using the design's palette
See `02` and `05`. The error state has a **Try Again** button. The empty state has none: a retry would return the same empty answer, and there's no edit flow to change the search.

---

## Visual / platform

### D-27 — System font (SF Pro) instead of the design's typeface ✔ Reviewed ↻ May change
The design uses a geometric brand typeface (Gilroy-like) that isn't licensed or supplied to us. SF Pro with sizes and weights matched to the design is the safe choice. All fonts come from one `Typography` enum, so swapping in the brand font is a one-file change.

### D-28 — Light appearance only, portrait only, fixed type sizes
- The design has a single colour scheme, so `overrideUserInterfaceStyle = .light` and the status bar uses light content.
- Dynamic Type isn't applied (the dense card layout is measured at fixed sizes). VoiceOver **is** supported through combined accessibility labels. This is a known limitation, listed in the README.

### D-29 — Colours sampled directly from the design PNGs
Exact hex values in `05-ui-spec.md` came from pixel sampling of `/design/*.png`, not from guesses.

### D-30 — Promo images: our own generic placeholder artwork, bundled as an asset
- The repo will be **public**, and `/design` plus the task PDF are git-ignored. Copying the design's "18% Discount / City Bank / AMEX" artwork (which also shows third-party bank logos) into the app would publish it anyway.
- Instead, a simple original image: navy background, a yellow "%" / tag glyph and the text "Up to 18% off", at the same size as the design (64×52 pt @2x/@3x). It's added to `Assets.xcassets` as `promo_discount`.
- The dummy `Promotion.imageName` refers to it, so no image loading or network dependency is needed.

### D-31 — Airline logos: loaded from SerpApi URLs by a small in-memory cache loader
`ImageLoader` (URLSession + `NSCache`) is behind a protocol. Cells cancel their pending load in `prepareForReuse` to avoid showing the wrong logo on a reused cell. A failed load shows the rounded placeholder.

---

## Architecture choices (details in `04`)

### D-32 — Everything is `Codable`; strict decoding; a decoding failure is the error state ✔ Reviewed
- **All models are `Codable`:** the SerpApi DTOs *and* the domain models (`FlightOffer`, `FlightEndpoint`, `LocalDateTime`, `FlightSearchRequest`, `Promotion`, `DateFare`, `SortOption`). This follows the brief literally ("Codable structs … such as `FlightOffer` and `FlightSearchRequest`").
- **Strict decoding:** no lossy arrays and no "flexible" number types. If the response doesn't match the DTOs, `JSONDecoder` throws, the service throws `FlightSearchError.decoding`, and the ViewModel shows the **error** state. A problem with the data is shown instead of hidden, and the decoding code stays simple enough to explain line by line.
- **Two steps: DTOs → pure mapper → `FlightOffer`.** A custom `init(from:)` on `FlightOffer` could decode and flatten in one go. We keep them separate:
  - the mapper can be tested with plain DTO values,
  - it handles the valid-but-incomplete groups from D-11,
  - `FlightOffer`'s own `Codable` conformance stays synthesized, so it encodes and decodes its *own* flat shape (tested as a round-trip), not SerpApi's nested one.

### D-33 — ViewModel outputs through a closure (`onStateChange`), not Combine
- It is plain Swift that any iOS developer can read, and the VC binds in one line.
- Tests don't need to subscribe: they `await viewModel.load()` and then check `state`, or record every value passed to `onStateChange` to check transitions.
- The ViewModel imports **Foundation only**, which is stricter than the brief's "no UIKit navigation types".

### D-34 — ViewModel formats display strings (ViewData), Views stay dumb
Price, duration, time, day offset and stop label formatting live in plain formatter structs that the ViewModel uses. Views don't hold any display logic, so formatting is unit-tested without UIKit.

### D-35 — Coordinator delegate has two methods
```swift
@MainActor
protocol FlightResultsCoordinatorDelegate: AnyObject {
    func didSelectFlight(_ offer: FlightOffer)
    func didSelectPromotion(_ promotion: Promotion)
}
```
This extends the brief's example and follows its rule: the ViewModel *reports what happened* and the Coordinator *decides how to navigate*. The ViewModel holds the delegate `weak`ly.
