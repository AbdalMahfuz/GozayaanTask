# 03 — Data Model & Mapping

## 1. Request

### 1.1 `FlightSearchRequest`
```swift
struct FlightSearchRequest: Codable, Hashable, Sendable {
    let originCode: String          // "DAC"   (IATA, uppercase, 3 letters)
    let destinationCode: String     // "JFK"
    let originCity: String          // "Dhaka"     – display only, not sent
    let destinationCity: String     // "New York"  – display only, not sent
    let outboundDate: Date          // calendar day; time part ignored
    let adults: Int                 // 2 (D-05)
    let currencyCode: String        // "BDT"
    let tripType: TripType          // .oneWay
}
enum TripType: String, Codable, Sendable { case oneWay = "One Way" }
```

### 1.2 HTTP request (`SerpApiRequestBuilder`)
`GET https://serpapi.com/search` (the endpoint from the brief) with these query items, **in this order** (fixed order makes the cache key and tests deterministic):

| Name | Value | Source |
|---|---|---|
| `engine` | `google_flights` | constant |
| `departure_id` | `DAC` | `originCode` |
| `arrival_id` | `JFK` | `destinationCode` |
| `outbound_date` | `2026-10-14` | `outboundDate`, formatted `yyyy-MM-dd`, `en_US_POSIX`, **UTC** calendar |
| `type` | `2` | `tripType == .oneWay` |
| `adults` | `2` | `adults` |
| `currency` | `BDT` | `currencyCode` |
| `hl` | `en` | constant |
| `gl` | `bd` | constant |
| `api_key` | *secret* | `AppConfig` — **appended last, excluded from cache key and logs** |

- Timeout: 30 s. Cache policy: `.reloadIgnoringLocalCacheData` (our own DEBUG cache handles caching).
- `outboundDate` is built in the **Gregorian calendar with UTC**, both when created and when formatted, so the date can't shift by a day between the device time zone and UTC.

## 2. Response DTOs (mirror SerpApi 1:1)

All DTOs are `Codable` (D-32). The decoder uses `keyDecodingStrategy = .convertFromSnakeCase`. Only the fields we use are declared; unknown fields are ignored. Optional (`?`) is used **only** where SerpApi really leaves the field out; everything else is required, so a shape change fails loudly.

```swift
struct SerpApiFlightsResponse: Codable, Sendable {
    let searchMetadata: SearchMetadataDTO?
    let bestFlights: [FlightGroupDTO]?
    let otherFlights: [FlightGroupDTO]?
    let error: String?
}

struct SearchMetadataDTO: Codable, Sendable { let status: String? }   // "Success" | "Processing" | "Error"

struct FlightGroupDTO: Codable, Sendable {
    let flights: [FlightLegDTO]
    let layovers: [LayoverDTO]?
    let totalDuration: Int?          // minutes
    let price: Int?                  // SerpApi omits it on some results (→ group skipped, D-11)
    let type: String?                // "One way"
    let airlineLogo: String?         // group-level logo (multi-airline logo when mixed)
    // departure_token / booking_token deliberately NOT declared (out of scope)
}

struct FlightLegDTO: Codable, Sendable {
    let departureAirport: AirportDTO
    let arrivalAirport: AirportDTO
    let duration: Int?               // minutes
    let airline: String?
    let airlineLogo: String?
    let flightNumber: String?        // "BG 147"
    let overnight: Bool?
}

struct AirportDTO: Codable, Sendable {
    let name: String?
    let id: String                   // IATA
    let time: String                 // "2026-02-15 12:30", airport-local, no TZ
}

struct LayoverDTO: Codable, Sendable {
    let duration: Int?
    let name: String?
    let id: String?
    let overnight: Bool?
}
```

### 2.1 Strict decoding (D-32)
- There are no lossy or tolerant decoding helpers. **Any** `DecodingError` (wrong root type, a required key missing in any group or leg, a type mismatch such as `"price": "37400"` or `37400.5`) → `FlightSearchError.decoding` → **error state**.
- DEBUG builds log the `DecodingError`'s `codingPath` and description (e.g. `best_flights[3].flights: keyNotFound`), so a failure can be diagnosed quickly. Release shows only the generic error text.
- What decoding does **not** reject is valid data the UI can't use (an absent optional `price`, an empty `flights` array, an unexpected time format). The mapper handles those in §4.7.

## 3. Domain model

```swift
struct FlightOffer: Codable, Hashable, Sendable, Identifiable {
    let id: String                     // stable identity, see §4.2
    let source: Source                 // .best | .other
    let airlineNames: [String]         // unique, in leg order; never empty
    let airlineLogoURL: URL?
    let departure: FlightEndpoint      // first leg's departure
    let arrival: FlightEndpoint        // last leg's arrival
    let arrivalDayOffset: Int          // calendar days, see §4.5 (can be 0, >0, <0)
    let totalDurationMinutes: Int      // > 0
    let stops: Int                     // legs.count - 1, >= 0
    let layoverAirportCodes: [String]  // e.g. ["DXB", "CMB"]; may be shorter than `stops` if data is missing
    let price: Int                     // whole units of `currencyCode`, > 0
    let currencyCode: String           // from the request (SerpApi prices use the requested currency)

    enum Source: String, Codable, Sendable { case best, other }
}

struct FlightEndpoint: Codable, Hashable, Sendable {
    let airportCode: String            // "DAC"
    let localDateTime: LocalDateTime   // wall-clock, airport-local
}

struct LocalDateTime: Codable, Hashable, Comparable, Sendable {
    let year: Int, month: Int, day: Int, hour: Int, minute: Int
    // Comparable: lexicographic (y, m, d, h, min)
}
```

`FlightOffer`'s `Codable` conformance is synthesized and encodes its own flat shape. A unit test checks that encoding and then decoding returns an equal value.

**Why `LocalDateTime` and not `Date`:** a `Date` is an absolute instant. SerpApi's times have no time zone, so turning them into a `Date` would invent one and let formatting move the time. A plain component struct can't be shifted by accident (D-12).

### Dummy-data models
```swift
struct Promotion: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let imageName: String      // asset catalog name
    let title: String          // "On International Flight Bookings"
    let url: URL               // https://www.gozayaan.com/...
}

struct DateFare: Codable, Hashable, Sendable {
    let date: Date
    let price: Int             // hard-coded
    let isSelected: Bool
}

enum SortOption: String, Codable, CaseIterable, Sendable { case cheapest, fastest }
```

Dummy content (`DummyContentProvider`):
- **Promotions (3):** all use title `On International Flight Bookings` and the image `promo_discount` (our own artwork, D-30). All 3 URLs are `https://www.gozayaan.com`, the address the brief names. Made-up sub-paths could lead to dead pages.
- **Date fares (7):** days −3…+3 around the search date. Prices: `70129, 74240, 120400, 68500, 81990, 95300, 77410`. The search date (index 3) is selected.

## 4. Mapping rules (`FlightOfferMapper`, a pure function)

```swift
struct FlightOfferMapper {
    func map(_ response: SerpApiFlightsResponse, request: FlightSearchRequest) -> [FlightOffer]
    func mapGroup(_ group: FlightGroupDTO, source: FlightOffer.Source, currencyCode: String) -> FlightOffer?
}
```

### 4.1 Pipeline
1. `groups = (bestFlights ?? []).map{(.best,$0)} + (otherFlights ?? []).map{(.other,$0)}`
2. `offers = groups.compactMap(mapGroup)`, dropping invalid groups (§4.7)
3. Remove duplicates by `id`, keeping the first
4. Return the list in API order (sorting belongs to the ViewModel, §5)

### 4.2 `id`
`legs.map { "\(flightNumber ?? airline ?? "?")@\(departureAirport.id)@\(departureAirport.time)" }.joined(separator: "|")`
Example: `BG 147@DAC@2026-02-15 12:30|EK 201@DXB@2026-02-15 22:10`
The id must stay the same across requests and re-sorts, and must be unique within one list (the diffable data source requires it).

### 4.3 Field-by-field

| `FlightOffer` field | Rule |
|---|---|
| `airlineNames` | `legs.compactMap(\.airline)` with duplicates removed, order kept. If that's empty, `["Unknown airline"]`. |
| `airlineLogoURL` | `URL(string: group.airlineLogo)` ?? `URL(string: legs.first?.airlineLogo)` ?? `nil` |
| `departure` | `legs.first!.departureAirport` → `(id, parse(time))` |
| `arrival` | `legs.last!.arrivalAirport` → `(id, parse(time))` |
| `stops` | `legs.count - 1` |
| `layoverAirportCodes` | `layovers?.compactMap(\.id) ?? legs.dropLast().map(\.arrivalAirport.id)` |
| `totalDurationMinutes` | `group.totalDuration` if > 0; otherwise `sum(legs.duration) + sum(layovers.duration)` if every value is present and the total > 0; otherwise **invalid** |
| `price` | `group.price` if > 0; otherwise **invalid** |
| `arrivalDayOffset` | §4.5 |

### 4.4 Time parsing
- Format `yyyy-MM-dd HH:mm`, parsed with a `DateFormatter` (locale `en_US_POSIX`, time zone UTC, Gregorian). The formatter is created **once** as a static, never per call.
- The resulting `Date` is split into components (UTC calendar) → `LocalDateTime`.
- If parsing fails, the group is **invalid**.

### 4.5 Day offset
`arrivalDayOffset` = the number of whole days between the calendar day `(arrival.y, m, d)` and `(departure.y, m, d)`, counted with a UTC Gregorian calendar. Hours are ignored.
- `2026-02-15 23:50 → 2026-02-16 00:30` gives **+1**, even though only 40 minutes pass.
- `2026-02-15 04:00 → 2026-02-16 08:20` gives **+1** (design: `08:20 +1Day`).
- `2026-02-15 09:30 → 2026-02-17 07:40` gives **+2** (design: `07:40 +2Day`).
- A negative result is allowed and shown as `-1Day`.

### 4.6 Stops label (formatter, not mapper)
| stops | label | timeline dots |
|---|---|---|
| 0 | `Non-Stop` | 0 |
| 1 | `1 Stop` | 1 |
| 2 | `2 Stop` | 2 |
| n ≥ 3 | `n Stop` | 3 (capped) |

### 4.7 A decoded group is invalid (dropped, not an error) when any of these hold
- `flights` is empty
- the first departure or last arrival `time` fails to parse, or the airport `id` is empty
- `price` is missing or ≤ 0
- a duration can't be determined (§4.3)

Every drop is counted, and DEBUG logs `Skipped N of M flight groups (reasons: …)`.

### 4.8 Response → service result (`SerpApiFlightSearchService`)

| HTTP | Body | Result |
|---|---|---|
| 2xx | decodes; `error == nil` | `mapper.map(...)`, which may be `[]` → the ViewModel makes it **empty** |
| 2xx | decodes; `error` is a no-results message | `[]` → **empty** |
| 2xx | decodes; `error` is another message | throw `.server(status: 200, message:)` |
| 2xx | `search_metadata.status == "Error"` and no `error` | throw `.server(status: 200, message: nil)` |
| 2xx | doesn't decode (**any** `DecodingError`, including a single broken group) | throw `.decoding` → error state |
| 401 / 403 | any | throw `.unauthorized` |
| 429 | any | throw `.rateLimited` |
| other | body `{"error": "..."}` if present | throw `.server(status:, message:)`; `.rateLimited` if message says "run out of searches" |
| – | `URLError` | `.offline` / `.timeout` / `.unknown`; `.cancelled` is rethrown as `CancellationError` |

## 5. Sorting (ViewModel, a pure static function)

```swift
static func sort(_ offers: [FlightOffer], by option: SortOption) -> [FlightOffer]
```
| Option | Primary | Tie-break 1 | Tie-break 2 | Tie-break 3 |
|---|---|---|---|---|
| `.cheapest` | `price` ascending | `totalDurationMinutes` ascending | `departure.localDateTime` ascending | original index (stable) |
| `.fastest` | `totalDurationMinutes` ascending | `price` ascending | `departure.localDateTime` ascending | original index (stable) |

Swift's `sorted(by:)` isn't guaranteed to be stable, so sort on `enumerated()` with the index as the last tie-break.

## 6. Formatting (Foundation-only, used by the ViewModel)

| Formatter | Input → Output | Examples |
|---|---|---|
| `PriceFormatter` | `(Int, "BDT")` → amount `"37,400"`, full `"BDT 37,400"` | `0→"0"`, `999→"999"`, `1000→"1,000"`, `120400→"120,400"`, `1234567→"1,234,567"` |
| `DurationFormatter` | minutes → string | `280→"4h 40m"`, `300→"5h"`, `45→"45m"`, `1640→"27h 20m"`, `3020→"50h 20m"` |
| `TimeFormatter` | `LocalDateTime` → `"HH:mm"` | `(…,4,0)→"04:00"` |
| `DayOffsetFormatter` | Int → `String?` | `0→nil`, `1→"+1Day"`, `2→"+2Day"`, `-1→"-1Day"` |
| `StopsFormatter` | Int → label | §4.6 |
| `HeaderDateFormatter` | Date → `"15 Oct, 2026"` | `dd MMM, yyyy`, `en_US_POSIX`, UTC |
| `ChipDateFormatter` | Date → `"Sun 08 Feb"` | `EEE dd MMM`, `en_US_POSIX`, UTC |
| `PassengerFormatter` | Int → `"01"` | `1→"01"`, `12→"12"` |

`PriceFormatter` uses a `NumberFormatter` with `numberStyle = .decimal`, `locale = en_US_POSIX`, `groupingSeparator = ","`, `groupingSize = 3`, `usesGroupingSeparator = true`, and `maximumFractionDigits = 0`. `en_US_POSIX` doesn't group by default, so the grouping settings must be set explicitly, and a test covers it.

## 7. ViewData (built by the ViewModel, rendered by Views)

```swift
struct RouteHeaderViewData: Equatable { let title: String        // "Dhaka - New York"
                                        let dateText: String     // "14 Oct, 2026"
                                        let passengerText: String // "02"
                                        let tripTypeText: String } // "One Way"

struct DateFareViewData: Hashable { let dateText: String; let priceText: String; let isSelected: Bool }

struct FlightCardViewData: Hashable, Identifiable {   // synthesized Equatable over ALL fields (not id-only)
    let id: String
    let airlineText: String          // "Air Arabia + US Bangla Airlines"
    let airlineLogoURL: URL?
    let departureTime: String        // "09:30"
    let departureCode: String        // "DAC"
    let arrivalTime: String          // "07:40"
    let arrivalDayOffsetText: String?// "+2Day"
    let arrivalCode: String          // "JFK"
    let durationText: String         // "50h 20m"
    let stopsText: String            // "2 Stop"
    let stopDotCount: Int            // 0...3
    let currencyCode: String         // "BDT"
    let priceText: String            // "202,972"
    let accessibilityLabel: String
}

struct PromotionViewData: Hashable, Identifiable { let id: String; let imageName: String; let title: String; let linkText: String }  // "Learn more"
struct EmptyStateViewData: Equatable { let title: String; let message: String }
struct ErrorStateViewData: Equatable { let kind: Kind; let title: String; let message: String; let debugDetail: String?
                                       enum Kind { case connectivity, general } }
```

Accessibility label example:
`"Biman Bangladesh Airlines. Departs DAC at 04:00. Arrives CVB at 08:20, next day. Duration 27 hours 20 minutes. 1 stop. Starting from BDT 78,880."`

## 8. Test fixtures (`FlightResultsTests/Fixtures/`)

Hand-written minimal JSON. Each covers one rule:

| File | Contents | Checks |
|---|---|---|
| `nonstop.json` | 1 best group, 1 leg DAC→BKK 12:30→16:50, 280 min, price 37400 | Basic mapping, `Non-Stop`, no day offset |
| `one_stop_overnight.json` | 2 legs DAC→DXB→CVB, departs 04:00 on the 15th, arrives 08:20 on the 16th | `1 Stop`, `+1Day`, layover code |
| `two_stop_multi_airline.json` | **3 legs**, 2 airlines, arrives 2 days later | **`2 Stop`**, `"A + B"` label, `+2Day`, group logo preferred |
| `missing_total_duration.json` | no `total_duration`; legs 100+120, layover 60 | duration = 280 |
| `invalid_groups.json` | 4 groups that decode fine: no `price` key, `flights: []`, time `"15/02/2026 12:30"`, and 1 valid | only 1 offer; no throw |
| `missing_required_key.json` | 1 valid group + 1 group **without the `flights` key** | service throws `.decoding` (strict) |
| `duplicates.json` | the same itinerary in best and other | 1 offer, `source == .best` |
| `best_and_other_order.json` | 2 best + 2 other | API order best-then-other kept by the mapper |
| `type_mismatch.json` | `"price": "37400"` (string) | service throws `.decoding` |
| `no_results_error.json` | `{"error":"Google Flights hasn't returned any results for this query."}` | service → `[]` |
| `api_error_200.json` | `{"error":"Invalid departure_id"}` | service → `.server(200, msg)` |
| `invalid_key_401.json` | `{"error":"Invalid API key. Your API key should be here: …"}` | `.unauthorized` |
| `empty_arrays.json` | `best_flights: []`, no `other_flights` | `[]` |
| `malformed.json` | `[1,2,3]` | `.decoding` |

App bundle fixture: `FlightResults/Resources/Fixtures/serpapi_dac_jfk_oneway.json` is a **real** captured response (captured once with the key, `api_key` removed from `search_parameters`/`search_metadata` URLs before committing).
