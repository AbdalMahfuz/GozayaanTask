# 06 — Acceptance Criteria ("Done")

Each criterion can be checked with a single pass/fail. **Verify** column:
- **UT**: automated unit test, named in the cell
- **MT**: manual test on the simulator (iPhone 17e / iOS 26.5, plus one run on iPhone 12 / iOS 18.0, the minimum version)
- **CR**: code review or grep check

The work is **done** when every row passes, the project builds with **0 warnings**, and all unit tests are green.

## A. Architecture
| ID | Criterion | Verify |
|---|---|---|
| A1 | No file in `Features/**/ViewModel`, `Features/**/Model`, `Features/**/Data`, `Core/Formatting`, `Core/Networking` imports `UIKit`, `SwiftUI` or `SafariServices` | CR: `grep -rE "import (UIKit\|SwiftUI\|SafariServices)"` on those paths returns nothing |
| A2 | `FlightResultsViewModel` doesn't refer to `FlightResultsCoordinator`, `UINavigationController`, `UIViewController`, `UIApplication` or `SFSafariViewController` | CR: grep |
| A3 | ViewModel reaches navigation only through `weak var coordinatorDelegate: FlightResultsCoordinatorDelegate?` | CR |
| A4 | View files don't refer to any Coordinator type or `FlightSearchService` | CR: grep |
| A5 | Only `FlightResultsCoordinator` creates `SFSafariViewController` | CR: grep |
| A6 | `FlightResultsViewModelTests` compiles and runs with no UIKit import and no Coordinator; delegate replaced by `SpyCoordinatorDelegate` | UT (the target itself) |
| A7 | No retain cycle: closing/replacing the screen deallocates VC and VM | UT `test_viewModel_isReleased_whenNoExternalReferences` (weak-ref check) + MT Memory Graph shows no cycle |
| A8 | Launch arguments and `#if DEBUG` data-source switching appear only in `AppEnvironment` | CR: grep `FRDataSource\|FRForceState` |
| A9 | Builds under Swift 6 language mode with 0 warnings | CR: `xcodebuild … build` output |
| A10 | Running the unit tests never starts the app's coordinators or a network request (unit-test guard, `04 §4`) | CR + MT: breakpoint/log in `AppCoordinator.start` is not hit during `xcodebuild test` |
| A11 | No `static` / global `DateFormatter` or `NumberFormatter`, and no `nonisolated(unsafe)` anywhere | CR: grep |

## B. Data: request & mapping
| ID | Criterion | Verify |
|---|---|---|
| B1 | Request URL contains `engine=google_flights`, `departure_id=DAC`, `arrival_id=JFK`, `outbound_date=YYYY-MM-DD`, `type=2`, `adults=2`, `currency=USD` (fixed wire currency — SerpApi rejects BDT, D-06), `hl=en`, `gl=bd`, `api_key=…` | UT `SerpApiRequestBuilderTests.test_buildsExpectedQueryItems` |
| B2 | `outbound_date` is the same calendar day whatever the device time zone (test with `Pacific/Kiritimati` and `Pacific/Pago_Pago`) | UT `test_outboundDate_isTimeZoneIndependent` |
| B3 | Non-stop fixture → 1 offer: `DAC 12:30 → BKK 16:50`, `stops 0`, `duration 280`, `price 37400`, `dayOffset 0` | UT `FlightOfferMapperTests.test_nonStop` |
| B4 | 2-leg overnight → `stops 1`, `dayOffset +1`, departure from leg 1, arrival from leg 2, layover code taken | UT `test_oneStop_overnight` |
| **B5** | **3-leg itinerary → `stops == 2`, label `"2 Stop"`**, arrival from leg 3, `dayOffset +2`, airline text `"A + B"` | UT `test_threeLegs_mapsToTwoStop` |
| B6 | Missing `total_duration` → sum of legs + layovers | UT `test_missingTotalDuration_sumsLegsAndLayovers` |
| B7 | Groups with no price / empty flights / unparsable time are dropped; the rest still map; nothing throws | UT `test_invalidGroups_areSkipped` |
| B8 | **Strict decoding:** a response with one group missing the required `flights` key → service throws `.decoding` → ViewModel shows the **error** state | UT `DecodingTests.test_missingRequiredKey_throwsDecoding` + VM test D4-style |
| B9 | `best_flights` come before `other_flights`; the duplicate itinerary appears once, with `source == .best` | UT `test_bestBeforeOther_andDeduplicates` |
| B10 | `"price": "37400"` (wrong type) → `.decoding`; a group with **no** `price` key decodes and is skipped by the mapper (not an error) | UT `DecodingTests.test_typeMismatch_throwsDecoding`, `FlightOfferMapperTests.test_missingPrice_isSkipped` |
| B13 | `FlightOffer` and `FlightSearchRequest` are `Codable`: encoding then decoding gives an equal value | UT `DecodingTests.test_domainModels_roundTrip` |
| B11 | Offer `id` is identical across two mappings of the same JSON, and unique within a result | UT `test_offerId_isStableAndUnique` |
| B12 | Times aren't shifted by device time zone (`12:30` stays `12:30` with TZ set to `America/New_York`) | UT `test_localTimes_areNotTimeZoneShifted` |

## C. Data: service & errors
| ID | Criterion | Verify |
|---|---|---|
| C1 | 200 + valid JSON → `[FlightOffer]` | UT `SerpApiFlightSearchServiceTests.test_success` |
| C2 | 200 + `"Google Flights hasn't returned any results…"` → returns `[]` (not throw) | UT `test_noResultsError_returnsEmpty` |
| C3 | 200 + both arrays empty or missing → `[]` | UT `test_emptyArrays_returnsEmpty` |
| C4 | 200 + other `error` → throws `.server(200, msg)` | UT `test_otherApiError_throwsServer` |
| C5 | 401 → `.unauthorized`; 429 → `.rateLimited`; 500 → `.server(500, _)` | UT `test_httpStatus_mapping` (parameterised) |
| C6 | Malformed JSON → `.decoding` | UT `test_malformedJson_throwsDecoding` |
| C7 | `URLError.notConnectedToInternet` → `.offline`; `.timedOut` → `.timeout`; `.cancelled` → `CancellationError` | UT `test_urlError_mapping` |
| C8 | Missing/empty API key → `.missingAPIKey` and **no** HTTP call made | UT `RemoteFlightsDataSourceTests.test_missingKey_doesNotHitNetwork` |
| C9 | Cache: second identical request within TTL doesn't call inner source; after TTL it does; non-2xx not cached; cache key excludes `api_key` | UT `CachedFlightsDataSourceTests` (4 tests) |
| C10 | `api_key` value never appears in log output (`redact` replaces it) | UT `LogTests.test_redactsApiKey` |
| C11 | Wire request always sends `currency=USD`; a `BDT` business request gets its offers' prices converted (`price × 122`) with `currencyCode == "BDT"` on the result (D-06) | UT `SerpApiRequestBuilderTests.test_buildsExpectedQueryItems`, `SerpApiFlightSearchServiceTests.test_success_convertsPriceToBusinessCurrency` |

## D. ViewModel: state
| ID | Criterion | Verify |
|---|---|---|
| D1 | Initial `state == .loading` | UT `test_initialState_isLoading` |
| **D2** | **loading → success**: service returns offers; recorded states `[.loading, .success(n)]`; cards sorted by cheapest | UT `test_load_success_transitions` |
| **D3** | **loading → empty**: service returns `[]`; recorded `[.loading, .empty]`; empty message contains origin, destination, date | UT `test_load_empty_transitions` |
| **D4** | **loading → error**: service throws `.offline`; recorded `[.loading, .error(kind: .connectivity)]` with offline title | UT `test_load_error_transitions` |
| D5 | Each `FlightSearchError` case produces the title/message from `02 §4` | UT `test_errorMapping_allCases` |
| D6 | State is `.loading` *while* the service is suspended | UT `test_stateIsLoading_whileRequestInFlight` (continuation-controlled mock) |
| D7 | `retry()` from error → `[.error, .loading, .success]` and service called twice | UT `test_retry_fromError_reloads` |
| D8 | Calling `load()` twice while loading → service called once | UT `test_concurrentLoad_isIgnored` |
| D9 | Cancellation → no state change after cancel | UT `test_cancellation_doesNotEmitError` |
| D10 | Card ViewData formatting: `"4h 40m"`, `"Non-Stop"`, `"+1Day"`, `"37,400"`, `"BDT"`, times `"04:00"` | UT `test_cardViewData_formatting` |
| D11 | Header ViewData: `"Dhaka - New York"`, `"14 Oct, 2026"` (for injected date), `"02"`, `"One Way"` | UT `test_headerViewData` |
| D12 | Date fares: 7 items, index 3 selected, text `"Wed 14 Oct"` / `"BDT 68,500"` | UT `test_dateFares` |

## E. ViewModel: sorting & intents
| ID | Criterion | Verify |
|---|---|---|
| E1 | `.cheapest`: ascending price; ties → shorter duration → earlier departure → original order | UT `FlightOfferSorterTests.test_cheapest_withTieBreaks` |
| E2 | `.fastest`: ascending duration; ties → lower price → earlier departure → original order | UT `test_fastest_withTieBreaks` |
| E3 | Sort is stable for fully equal offers | UT `test_sort_isStable` |
| E4 | `selectSort(.fastest)` in success → emits `.success` with reordered cards, same set of ids | UT `test_selectSort_resortsInPlace` |
| E5 | `selectSort` with the current option → no emission | UT `test_selectSameSort_doesNotEmit` |
| E6 | `selectSort(.fastest)` during loading → final success is sorted by fastest | UT `test_sortChosenDuringLoading_appliesToResults` |
| E7 | `didSelectFlight(id:)` → delegate receives the matching `FlightOffer`; unknown id → no call | UT `test_didSelectFlight_forwardsToDelegate` |
| E8 | `didSelectPromotion(id:)` → delegate receives the matching `Promotion` | UT `test_didSelectPromotion_forwardsToDelegate` |
| E9 | Delegate is weak: VM doesn't retain the spy | UT `test_delegate_isWeak` |

## F. Formatters
| ID | Criterion | Verify |
|---|---|---|
| F1 | Price: `0, 999, 1000, 37400, 120400, 1234567` → `"0","999","1,000","37,400","120,400","1,234,567"`, same result when device locale is `bn_BD` or `hi_IN` | UT `FormatterTests.test_price` |
| F2 | Duration: `45→"45m"`, `60→"1h"`, `280→"4h 40m"`, `1640→"27h 20m"`, `3020→"50h 20m"` | UT `test_duration` |
| F3 | Day offset: `0→nil`, `1→"+1Day"`, `2→"+2Day"`, `-1→"-1Day"` | UT `test_dayOffset` |
| F4 | Stops: `0→"Non-Stop"`, `1→"1 Stop"`, `2→"2 Stop"`, `3→"3 Stop"`; dots capped at 3 | UT `test_stops` |
| F5 | Dates: header `"15 Feb, 2026"`, chip `"Sun 15 Feb"`, passengers `2→"02"`, `1→"01"` | UT `test_dates_and_passengers` |

## G. UI: manual checks against `../design`
| ID | Criterion | Verify |
|---|---|---|
| G1 | **Loading** looks like `…One Way-1.png`: progress bar, "Hang tight!" text, 3 shimmering skeletons, carousel after skeleton 2, strip fares as shimmer bars, chart border grey | MT (scheme *Loading*), screenshot in `docs/screenshots/loading.png` |
| G2 | **Success** looks like `…One Way.png`: card layout, fonts, colours, dashed separator, `+1Day` superscript placement, carousel after card 2 | MT (scheme *Fixture*), screenshot `success.png` |
| G3 | **Empty** state shows icon/title/message, no carousel, sort disabled | MT (scheme *Empty*), `empty.png` |
| G4 | **Error** state shows icon/title/message/Try Again; Try Again shows loading again | MT (scheme *Error*), `error.png` |
| G5 | Header shows route, date, 👤 02, One Way, back chevron, and **no** Edit button; back/Filter/chart/Get Points do nothing and don't crash | MT |
| G6 | Date strip scrolls horizontally; selected chip (search date) is visible & yellow on launch; tapping chips changes nothing | MT |
| G7 | Header, strip and sort bar stay pinned while the list scrolls | MT |
| G8 | Carousel scrolls sideways with centred paging, cards peek on both sides | MT |
| G9a | Promo image is our own `promo_discount` artwork; nothing from the design is in the repo (`git ls-files` shows no PNG copied from the design) | CR |
| G9 | Tapping a promo card (or Learn more) opens gozayaan.com in Safari View Controller; Done returns to the list at the same scroll position | MT |
| G10 | Sort dropdown matches `Cheapest (Sorting Drop Down).png`; choosing Fastest reorders cards with move animation, no scroll jump; button title becomes "Fastest"; outside tap dismisses | MT, screenshot `sort.png` |
| G11 | Long airline name (`Air Arabia + US Bangla Airlines`) truncates with `…` and doesn't push "Get Points" | MT (fixture has one) |
| G12 | Airline logos load; fast scrolling never shows a wrong logo in a reused cell | MT |
| G13 | Shimmer keeps animating after backgrounding + foregrounding the app during loading | MT (scheme *Loading*) |
| G14 | Reduce Motion ON: no shimmer sweep, no progress animation, app still usable | MT |
| G15 | VoiceOver reads a flight card as one element with the full label (see `03 §7`) | MT |
| G16 | Live run with real key: success list appears with real SerpApi data; second launch within 6 h makes no network call (verify in console log `cache hit`) | MT |
| G17 | Run without `Secrets.xcconfig`: app builds, shows "Search unavailable" error (not a crash, not fake data) | MT |
| G18 | Works on smallest supported width (375 pt, e.g. iPhone SE 3rd gen — create sim if needed) and a large one (iPhone Air, 420 pt) without clipping | MT |

## H. Deliverables
| ID | Criterion | Verify |
|---|---|---|
| H1 | Repo root holds `FlightResults.xcodeproj`, `/spec`, `README.md`, `NOTES.md`, `.gitignore` | CR |
| H2 | `Secrets.xcconfig` is git-ignored; `git log -p` shows no API key ever committed; bundled fixture has `api_key` stripped | CR: `git log -p \| grep -i "api_key="` shows only placeholders |
| H3 | README explains: add key, the 5 schemes, run tests, known limitations (D-07, D-27, D-28) | CR |
| H4 | NOTES.md lists AI tool, what was corrected/thrown away (with concrete examples), which decisions were mine | CR |
| H5 | Commit history follows `07` step by step (small, descriptive commits) | CR |
| H6 | `xcodebuild test -scheme FlightResults -destination 'platform=iOS Simulator,name=iPhone 17e'` passes from a clean clone | CR |
