# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Flyball** — a Flutter mobile app of football trivia mini-games with a Dark-Mode
Neo-Brutalist aesthetic (deep charcoal `#121212`, neon "Pitch Green" `#39FF14`,
sharp white; thick borders, hard un-blurred drop shadows, blocky corners,
Space Grotesk via `google_fonts`).

Three games exist; only the first is fully implemented:
- **Football XOX** — fully built. A 3×3 trivia grid; each row/column gets a
  random unique factor (category) and each cell needs a footballer satisfying
  BOTH the row and column factor.
- **Footballdle** and **1 Team 1 Country** — "Coming Soon" placeholders.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on a connected device/emulator
flutter run -d chrome           # run in the browser
flutter analyze                 # static analysis / lints (keep at zero issues)
flutter test                    # run all tests
flutter test test/factor_pool_test.dart   # run a single test file
```

### API key (player search)
Player search uses **API-Football**. The key is injected at build/run time and
never committed:

```bash
flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
```

Get a free key at https://www.api-football.com (free plan ≈ 100 requests/day).
**Without a key the app still runs** — search falls back to a curated offline
player corpus and the sheet shows a clear "no API key" banner.

## Architecture

```
lib/
  main.dart                       # MaterialApp + theme + routes
  config/app_config.dart          # reads API_FOOTBALL_KEY (--dart-define)
  theme/                          # app_colors.dart, app_theme.dart (design system)
  routing/app_routes.dart         # named routes + onGenerateRoute
  widgets/                        # brutalist_button, brutalist_card, flyball_logo (CustomPaint)
  screens/                        # home, football_xox, coming_soon (+ 2 placeholders)
  game/xox/                       # factor.dart, factor_pool.dart, xox_cell.dart (game models)
  data/                           # player, player_repository, api_football_repository, player_attributes
  ui/xox/player_search_sheet.dart # modal search bottom sheet
```

### The key design decision: search vs. validation
No free football API can pre-filter "every footballer past & present" by
leagues-played + titles-won + nationality within its request quota. So Flyball
**splits the two concerns**:

- **Search** (finding real players by name, incl. retired) → API-Football, via
  `ApiFootballRepository._searchApi`.
- **Validation** (does a candidate satisfy the two factors?) → a curated local
  table in [data/player_attributes.dart](lib/data/player_attributes.dart). The
  API result is *enriched* with these attributes, then filtered.

This is "block at search": [PlayerRepository.searchValid](lib/data/player_repository.dart)
only ever returns players valid for BOTH the row and column factor, so anything
the user can tap in the sheet is a legal answer. The repository is an abstract
`PlayerRepository`, so the data source can be swapped (API / local JSON / hybrid)
without touching UI.

### Factors & board generation
[game/xox/factor.dart](lib/game/xox/factor.dart) — a `Factor` has a `FactorType`
(playedLeague / wonLeague / wonInternational / team / nationality), a display
`label`, a canonical `value`, and a `matches(Player)` predicate. Equality is by
`(type, value)`.

[game/xox/factor_pool.dart](lib/game/xox/factor_pool.dart) holds the catalogue
(6 leagues × {played, won}, 3 international tournaments, ~20 clubs, exactly 75
nationalities) and `generateBoard()`, which returns 3 row + 3 column factors
that are **all six unique**.

## Extending

- **More players / better validation coverage**: add `Player` entries to
  `PlayerAttributes` in [data/player_attributes.dart](lib/data/player_attributes.dart).
  Keys match the player's display name (case-insensitive, partial-tolerant).
  League/title/team strings MUST match the canonical names in `FactorPool`.
- **Swap the data source**: implement `PlayerRepository` and inject it via
  `FootballXoxScreen(repository: ...)`.
- **New factor type**: add to `FactorType`, extend `Factor.matches`, and emit it
  from `FactorPool.allFactors()`.

## Conventions

- `StatefulWidget` for game state (no state-management package).
- Use the shared `BrutalistCard` / `BrutalistButton` rather than re-styling
  containers; pull colours from `AppColors` and text styles from `AppTheme`.
- Grid/headers must scale to fit common phone sizes without overflow (the XOX
  board uses `LayoutBuilder` + `FittedBox`).
