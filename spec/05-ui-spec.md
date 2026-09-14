# 05 — UI Spec

**Source of truth:** `/design` (kept local and git-ignored; the reviewers have the same frames in their Figma file)
| File | Frame |
|---|---|
| `Flight Result - After Search, One Way-1.png` | **Loading** (skeleton shimmer) |
| `Flight Result - After Search, One Way.png` | **Success** (card list) |
| `Cheapest (Sorting Drop Down).png` | **Sort dropdown open** |

The frames are 750 px wide, i.e. an iPhone 375 pt canvas at @2x. All sizes below are in **points** (px ÷ 2) and were measured from the PNGs. **Tolerance: ±2 pt.** Colours were pixel-sampled and are exact.

## 1. Design tokens (`Core/UI/Theme.swift`)

### 1.1 Colours
| Token | Hex | Used for |
|---|---|---|
| `navy` | `#00026E` | Screen background, price amount, dropdown text, promo image backdrop |
| `yellow` | `#FDCC02` | Selected chip text + indicator, chart button border (success), Filter button background, Try Again button |
| `brandBlue` | `#4073BF` | Strip divider, timeline line + dots, skeleton blocks, links |
| `textPrimary` | `#022738` | Airline name, times, Filter text, promo title |
| `textSecondary` | `#546378` | Airport codes, duration, stops, "Get Points", "Starting from", "BDT", Learn more |
| `separator` | `#DBDDE0` | Dashed card divider |
| `dayOffsetRed` | `#F33A3A` | `+1Day` |
| `cardBackground` | `#FFFFFF` | Flight card, dropdown panel, progress track |
| `promoMint` | `#E5FFEC` | Promo card text area |
| `progressOrange` | `#FF6F00` | Loading progress fill |
| `selectionTint` | `#ECF3FE` | Selected dropdown row |
| `sortBorder` | `#BCC9DC` | Sort button border |
| `chartBorderLoading` | `#A5ABB2` | Chart button border while loading |
| `skeletonStart` → `skeletonEnd` | `#0D2184` → `#1C4AA0` | Skeleton card horizontal gradient (left → right) |
| `onNavy` | `#FFFFFF` | Header text, unselected chips, sort text, state texts |
| `onNavySecondary` | `#FFFFFF` @ 80 % | Empty/error message |

### 1.2 Typography (SF Pro, D-27)
| Token | Size / weight | Used for |
|---|---|---|
| `headerTitle` | 22 bold | "Dhaka - New York" |
| `headerSubtitle` | 15 regular | "15 Feb, 2025 \| 👤 02 \| One Way" |
| `chipDate` | 15 regular | "Sun 08 Feb" |
| `chipPrice` | 17 medium | "BDT 70,129" |
| `button` | 16 semibold | Cheapest, Filter, Try Again |
| `loadingTitle` | 20 semibold, line height 30, centred | "Hang tight! …" |
| `airline` | 16 regular | Airline name |
| `points` | 14 regular | "Get Points" |
| `time` | 18 bold | "12:30" |
| `airportCode` | 15 regular | "DAC" |
| `meta` | 14 regular | Duration, stops, "Starting from" |
| `dayOffset` | 11 medium | "+1Day" |
| `currency` | 13 regular | "BDT" on the card |
| `price` | 20 bold | "37,400" |
| `promoTitle` | 13 medium, 2 lines | Promo title |
| `promoLink` | 11 regular, underlined | "Learn more" |
| `stateTitle` | 20 semibold | Empty/error title |
| `stateMessage` | 15 regular | Empty/error message |

### 1.3 Spacing & radii
`screenInset = 16`, `cardPadding = 16`, `cardSpacing = 12`, `cardRadius = 12`, `skeletonRadius = 16`, `buttonRadius = 6`, `chipIndicatorHeight = 3`, `promoRadius = 8`, `dropdownRadius = 12`.

## 2. Screen layout (top → bottom)

The whole screen background is `navy`, including behind the status bar. Status bar style: `.lightContent`. The navigation bar is hidden.

```
┌ safe area top ───────────────────────────────┐
│ [‹]      Dhaka - New York                    │  RouteHeaderView      h ≈ 64
│      14 Oct, 2026 | 👤 02 | One Way          │
│ Sun 08 Feb  Mon 09 Feb  Tue 10 Feb  … │[📈]│ │  DateFareStripView    h = 64
│ BDT 70,129  BDT 74,240  BDT 120,400   │    │ │
│ ▔▔▔▔▔▔▔▔▔ (yellow 3pt under selected)        │
│───────────── 1pt brandBlue divider ──────────│
│ [Cheapest ˅]                     [Filter ⚙] │  SortFilterBarView    top 16, h 32
├─ pinned above / scrolling below ─────────────┤
│  UICollectionView (top inset 16)             │
└──────────────────────────────────────────────┘
```

### 2.1 RouteHeaderView
- Back chevron: SF Symbol `chevron.left`, 20 pt regular, white, leading 16. Hit area 44×44. **Decorative**: tapping does nothing.
- Title: centred on the screen (not between the buttons), 1 line, shrinks to a minimum scale of 0.8.
- Subtitle, centred 4 pt below the title: `{date}` ` | ` 👤`{pax}` ` | ` `{One Way}`. The person icon is SF Symbol `person`, 12 pt, white, with 2 pt before the number.
- No Edit button (D-19). The trailing side is empty, as in the design.
- Top: 12 pt below the safe area. Bottom: 16 pt to the strip.

### 2.2 DateFareStripView
- A horizontal `UICollectionView` (or `UIScrollView` + `UIStackView`) that **scrolls**, with scroll indicators hidden. It spans from the screen's leading edge to 8 pt before the chart button, and content can run under the leading edge (the design shows the first chip cut off).
- Chip: width 100, height 64. Date label on top (`chipDate`), price below (`chipPrice`), both centred.
  - Unselected: both labels `onNavy`.
  - Selected: both labels `yellow`, plus a 3 pt `yellow` indicator along the chip's bottom edge, full chip width.
- Loading: price label hidden and replaced by a 70×12 rounded (6) shimmer bar in its place.
- Taps are ignored (`isUserInteractionEnabled` stays on for scrolling, but selection doesn't change).
- On first layout, the selected chip is scrolled to the horizontal centre, without animation.
- Chart button: 40×40, radius 8, 1 pt border (`yellow` in success/empty/error, `chartBorderLoading` in loading), icon SF Symbol `chart.line.uptrend.xyaxis` 18 pt in the same colour. Trailing 16, vertically centred on the strip. **Decorative**.
- Divider: 1 pt `brandBlue`, full width, directly under the strip (the yellow indicator overlaps it).

### 2.3 SortFilterBarView
- Top 16 below the divider, height 32, insets 16.
- **Sort button** (leading): background clear, 1 pt `sortBorder`, radius 6, content insets h 12. Title `Cheapest` or `Fastest` (the current option), `button` font, white, then 8 pt, then SF Symbol `chevron.down` 12 pt semibold white. The chevron turns to `chevron.up` while the dropdown is open, with a 0.2 s rotation.
- **Filter button** (trailing): width 100, `yellow` background, radius 6. `Filter` in `button` font `textPrimary`, 8 pt, then SF Symbol `slider.horizontal.3` 14 pt `textPrimary`. **Decorative**.
- In empty/error states the sort button is disabled at 50 % alpha. Filter stays as it is (decorative anyway).

### 2.4 SortDropdownView (open state)
- An overlay added to the VC's root view above everything. A full-screen transparent backdrop catches outside taps and dismisses.
- Panel: width 200, leading 16, top = sort button bottom + 8. Background white, radius 12, shadow black 12 % / y 4 / blur 16.
- Content insets 16. Two rows, height 40, spacing 8. Text `button` font, weight **bold**, colour `navy`, leading inset 16.
- Selected row: `selectionTint` background, radius 6.
- Tapping a row calls `viewModel.selectSort(option)` and dismisses (0.15 s fade). Tapping the already-selected row just dismisses.
- VoiceOver: panel is `accessibilityViewIsModal = true`; rows have the `.button` trait, and the selected one adds `.selected`.

## 3. Collection view content

The layout is compositional. List sections are a single column, width = screen − 32, self-sizing height (estimated 180).

### 3.1 FlightCardCell (success)
```
┌───────────────────────────────────────────────────┐ radius 12, white, padding 16
│ [logo] Biman Bangladesh Airlines…      (🪙) Get Points │ row 1
│                                                   │ 16
│ 12:30          4h 40m               16:50⁺¹ᴰᵃʸ    │ row 2
│ DAC        ○────●────●────○             BKK       │
│                Non-Stop                           │
│                                                   │ 16
│ - - - - - - - - - - - - - - - - - - - - - - - - - │ dashed 1pt separator
│                                   Starting from   │ 12
│                                   BDT  37,400     │
└───────────────────────────────────────────────────┘
```
**Row 1**
- Logo 20×20, radius 4, `scaleAspectFit`, placeholder `systemGray5` rounded square. Loaded through `ImageLoading`; the load is cancelled and reset in `prepareForReuse`.
- Airline name: 8 pt after the logo, `airline` font `textPrimary`, 1 line, **tail truncation**, content compression resistance **lower** than the points group.
- Points group (trailing): coin icon 18×18 (asset `coin`; fallback SF Symbol `bitcoinsign.circle.fill` tinted `yellow`), 6 pt, `Get Points` `points` font `textSecondary`. **Decorative**, not a button.

**Row 2**: three columns, 16 pt below row 1.
- Left column (leading): time (`time` font `textPrimary`), 4 pt, then the code (`airportCode` `textSecondary`), both leading-aligned.
- Centre column, centred on the card: duration (`meta` `textSecondary`), 6 pt, **timeline** (width 92, height 8), 6 pt, stops label (`meta` `textSecondary`).
- Right column (trailing): a horizontal pair `[time][dayOffset]`, with `dayOffset` top-aligned to the time's cap height as a superscript and 1 pt gap. The code below is **trailing-aligned to the time label, not to the superscript** (design: `CVB` sits under `08:20`, not under `+1Day`). If there's no offset, the superscript label is hidden and takes no width.
- The columns must not overlap. The centre column has fixed width 100, and the side columns fill the remaining space with a minimum 8 pt gap.

**FlightTimelineView**
- Horizontal 1.5 pt `brandBlue` line between two end circles: 8×8, 1.5 pt `brandBlue` stroke, white fill.
- `stopDotCount` filled `brandBlue` dots, 7×7, spread evenly: 1 dot at 50 %, 2 dots at 45 %/55 % close together (as in the design), 3 dots at 25/50/75 %.

**Separator**: 1 pt dashed line (dash 4, gap 3), `separator` colour, 16 pt below row 2, spanning the card's content width.

**Price block**: trailing, 12 pt below the separator.
- `Starting from` (`meta` `textSecondary`), trailing-aligned.
- 4 pt below: `[BDT][6pt][37,400]`, **baseline-aligned**; `BDT` uses `currency` `textSecondary`, the amount uses `price` `navy`.
- Bottom padding 16.

**Interaction**: tapping the whole card calls `viewModel.didSelectFlight(id:)`. Highlight feedback: 0.97 scale while pressed, 0.15 s.
**Accessibility**: the cell is a single element; `accessibilityLabel` comes from ViewData; trait `.button`.

### 3.2 Promo carousel (section `.promotions`)
- Orthogonal scrolling `.groupPagingCentered`; item size 204×52; inter-item spacing 8; section insets top 16 (15–16 in design), bottom 16 (in addition to normal card spacing).
- **PromoCardCell**: radius 8, 1 pt white border, clipped.
  - Left: image area 64 wide, `navy` background, asset `promo_discount`, `scaleAspectFit`.
  - Right: `promoMint` background, content insets l 12 / r 8 / t 6 / b 6.
    - Title `promoTitle` `textPrimary`, max 2 lines, tail truncation.
    - Then `Learn more` (`promoLink`, underlined, `textSecondary`) + SF Symbol `arrow.up.right` 8 pt `textSecondary`, leading-aligned, at the bottom.
- The whole cell is tappable and calls `viewModel.didSelectPromotion(id:)`. Accessibility label: `"{title}. Learn more, opens gozayaan.com"`, trait `.link`.

### 3.3 LoadingBannerCell (loading only, first item)
- Progress bar: full content width (343), height 8, radius 4, track white, fill `progressOrange`. Fill animation from §2.1 of `02`.
- 24 pt below: `Hang tight! We’re finding the best flight options for you.`, `loadingTitle`, white, centred, up to 3 lines. 36 pt bottom spacing before the first skeleton.

### 3.4 SkeletonCardCell (loading only; 3 items, carousel after #2)
- Size: content width × 116, radius 16, background horizontal gradient `skeletonStart → skeletonEnd`. Spacing between skeletons: 8.
- Blocks (all `brandBlue`):
  - Circle 24×24 at (16, 24)
  - Line 1: 200×8, radius 4, at (48, 26)
  - Line 2: 100×8, radius 4, at (48, 40)
  - Pill: 48×16, radius 4, at (16, 76)
- **Shimmer**: a `CAGradientLayer` mask sweeping left → right across the blocks, with colours [clear, white 35 %, clear], animated `locations` from `[-1, -0.5, 0]` to `[1, 1.5, 2]`, duration 1.2 s, linear, repeating forever.
  - The animation is (re)added in `didMoveToWindow` and in `applyLayoutAttributes` / when shown, so it survives cell reuse and app backgrounding (`UIApplication.willEnterForegroundNotification` restarts it).
  - Reduce Motion: no sweep, blocks shown static.
- Skeleton cells aren't interactive and are hidden from VoiceOver. The loading banner cell has the announcement label "Loading flights".

### 3.5 EmptyStateView / ErrorStateView (collection `backgroundView`)
- A vertical stack centred horizontally, top at 25 % of the collection's height, side insets 32, spacing 12.
- Icon: 48 pt SF Symbol in `brandBlue` (error: `yellow`).
- Title `stateTitle` white, centred. Message `stateMessage` `onNavySecondary`, centred, unlimited lines.
- Error only: **Try Again** button 24 pt below the message, 200×44, `yellow` background, radius 8, `button` font `textPrimary`. Tap calls `viewModel.retry()`.
- DEBUG detail (error only): 12 pt monospaced, white at 50 %, below the button.

## 4. Motion summary
| Event | Animation |
|---|---|
| loading → success/empty/error | Apply snapshot, then cross-dissolve the collection view 0.25 s |
| Sort change | `apply(snapshot, animatingDifferences: true)`: cards move to their new positions |
| Dropdown open/close | Fade + 0.95 → 1 scale, 0.15 s; chevron rotates 0.2 s |
| Card press | Scale 0.97, 0.15 s |
| Retry | Immediately back to the loading layout (no animation) |
All respect `UIAccessibility.isReduceMotionEnabled` (fades only, no shimmer, no progress animation).

## 5. Assets to produce
| Asset | Source |
|---|---|
| `promo_discount` | **Our own artwork** (D-30): navy background, yellow tag/% glyph, "Up to 18% off" in white. 64×52 pt at @2x and @3x. Nothing copied from `/design`. |
| `coin` | Crop from success PNG around "Get Points" coin (@2x), or the SF Symbol fallback |
| `airline_placeholder` | Generated: rounded rect `systemGray5` |
| AppIcon | Simple navy + yellow plane glyph (optional polish) |
