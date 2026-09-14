# 00 — Overview

> GoZayaan iOS take-home: **Flight Results** screen.
> Spec written before any code (Option A). It drives the AI and is what the finished work is checked against.

## 1. Goal

Build one iOS screen, **Flight Results**. It shows one-way flights from the SerpApi Google Flights API and must support all four states: **loading, success, empty, error**. The app uses **UIKit** and **MVVM + Coordinator**, with strict layer boundaries. The ViewModel must be unit-testable with no UIKit and no Coordinator.

## 2. Documents in this folder

| File | What it covers |
|---|---|
| `00-overview.md` | Goal, scope, out-of-scope items, glossary, tooling |
| `01-decisions.md` | Every open point the brief left to us, with the decision and why |
| `02-screen-states.md` | The 4 states, what triggers each, transitions, what shows in each |
| `03-data-model-and-mapping.md` | SerpApi response DTOs, the `FlightOffer` model, flattening rules, edge cases, test fixtures |
| `04-architecture.md` | Layers, types, protocols, dependency injection, import rules, concurrency, errors |
| `05-ui-spec.md` | Visual spec measured from `../design`: colours, sizes, components, motion, accessibility |
| `06-acceptance-criteria.md` | Numbered, testable "done" criteria, each tied to a unit test or manual check |
| `07-implementation-plan.md` | Step-by-step build order (one AI prompt per step and one commit per step), plus a review checklist |

## 3. Scope

### In scope (required)
1. **Route header**: origin → destination, date, passenger count, "One Way", back chevron (decorative). No Edit button: the design has none (D-19).
2. **Date & price strip**: hard-coded dummy chips (`Sun 08 Feb` / `BDT 70,129`). The selected chip is highlighted. It scrolls horizontally, and taps are ignored.
3. **Loading skeletons**: shimmer cards, a progress bar and a "Hang tight!" message.
4. **Flight cards**: airline, departure and arrival times (with a +N day marker), duration, stops (Non-Stop / 1 Stop / 2 Stop), both airport codes, and the starting price.
5. **Discount carousel**: horizontally scrolling promo cards (image, title, Learn more) placed between flight cards. The data is dummy. **Learn more opens gozayaan.com through the Coordinator**, which is the only real navigation.
6. **Four states**: loading, success, empty, error, each reachable on demand (see `02`).
7. **Data**: a live SerpApi request, flattened into our own `FlightOffer`.

### In scope (extra credit, committed to)
8. **Sorting**: the Cheapest / Fastest dropdown works, and the list reorders in place. Sorting happens in the ViewModel as a pure function.
9. **Unit tests**: mapping (including a 3-leg result → "2 Stop"), ViewModel state transitions, sorting, formatters, and the network error mapping. The network layer is stubbed.

### Out of scope
- The Edit button and flow (D-19), the Filter screen, the price-trend (chart) button, "Get Points", and the back navigation. All are **visible but do nothing**.
- Tapping a date chip.
- Flight details or booking. `departure_token` and `booking_token` are ignored. Tapping a flight card is still sent to the Coordinator through the delegate the brief requires, and the Coordinator only logs it (see D-18).
- Round trips, multi-city, and multiple passenger types.
- Localisation (English only), dark mode (the design has a single look), iPad and landscape layouts.
- UI and snapshot tests.

## 4. Deliverables (from the brief)
- `/spec`: this folder.
- The Xcode project at the repo root. **Repo layout:** the git repo is the `FlightResults/` folder inside the local workspace. The brief PDF and `design/` sit next to it in the workspace (`../design`), outside the repo, so they can't be pushed by accident.
- `NOTES.md`: which AI tool was used, what was corrected or thrown away, and which decisions were our own.
- `README.md`: how to run the app (API key setup, schemes, forcing each state).
- Git history kept, with one meaningful commit per step in `07`.

## 5. Tooling baseline
| Item | Value |
|---|---|
| Xcode | 26.5 |
| Swift | 6.x, **Swift 6 language mode** (strict concurrency) |
| Minimum iOS | 18.0 (D-01) |
| Device | iPhone, portrait only |
| UI | UIKit, all in code (no storyboards except LaunchScreen) |
| Dependencies | **None** (no SPM or CocoaPods packages) |
| Tests | XCTest (`FlightResultsTests` target, no host-app UI) |
| AI tool | Claude Code |

## 6. Glossary
| Term | Meaning |
|---|---|
| **Offer** / `FlightOffer` | One bookable itinerary (one card). It can contain several legs. |
| **Leg** | One entry in SerpApi `flights[]`, i.e. one take-off and one landing |
| **Stop** | A connection between legs. `stops = legs - 1` |
| **Group** | One element of SerpApi `best_flights[]` or `other_flights[]` |
| **DTO** | A `Codable` struct that mirrors SerpApi JSON exactly. Never shown in the UI. |
| **ViewData** | A display-ready struct built by the ViewModel (already-formatted strings). Views render it without any logic. |
| **Fixture** | A JSON file of a SerpApi response, bundled for offline runs and tests |
