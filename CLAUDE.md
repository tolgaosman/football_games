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

### Player data (Transfermarkt API)
Player search & validation use a **self-hosted Transfermarkt API**
([felipeall/transfermarkt-api](https://github.com/felipeall/transfermarkt-api),
Python/FastAPI). Run it, then point the app at it via `--dart-define`:

```bash
docker run -p 8000:8000 transfermarkt-api          # start the service
flutter run --dart-define=TRANSFERMARKT_BASE_URL=http://localhost:8000
# from an Android emulator, reach the host with 10.0.2.2:
flutter run --dart-define=TRANSFERMARKT_BASE_URL=http://10.0.2.2:8000
```

No API key/auth is needed. **If the service is unreachable**, search degrades to
the curated offline cache in [player_attributes.dart](lib/data/player_attributes.dart)
and the search has both a per-request and an overall timeout so the UI never
hangs.

## Architecture

```
lib/
  main.dart                       # MaterialApp + theme + routes
  config/app_config.dart          # reads TRANSFERMARKT_BASE_URL (--dart-define)
  theme/                          # app_colors.dart, app_theme.dart (design system)
  routing/app_routes.dart         # named routes + onGenerateRoute
  widgets/                        # brutalist_button, brutalist_card, flyball_logo (CustomPaint)
  screens/                        # home, football_xox, coming_soon (+ 2 placeholders)
  game/xox/                       # factor.dart, factor_pool.dart, board_solver.dart, xox_cell.dart
  data/                           # player, player_repository, transfermarkt_service,
                                  #   api_football_repository (TransfermarktRepository), player_attributes
  ui/xox/player_search_sheet.dart # modal search bottom sheet
```

### The key design decision: search + validation from Transfermarkt
A footballer's leagues, clubs, nationality and **trophies** all come from the
Transfermarkt API ([transfermarkt_service.dart](lib/data/transfermarkt_service.dart)):

- **Search** `/players/search/{name}` finds real players (incl. retired).
- **Enrich** each candidate from `/profile` (nationality + current club),
  `/transfers` (clubs played for) and `/achievements` (league titles +
  international wins), mapped to `FactorPool` canonical names. Endpoints are
  fetched in parallel; candidates are cheap-prefiltered before enrichment.
- **Validate**: `Factor.matches` checks the resulting structured sets.

Notes that bit us before, keep in mind:
- `leaguesPlayed` is derived from clubs (transfers **and** `profile.club`,
  `mostGamesFor`, `lastClubName`) **plus** won league titles — so one-club /
  academy players (no senior transfers, e.g. Lamine Yamal) still resolve.
- The Euros win is labelled "European champion(ship)"; exclude "Europa".

This is "block at search": [PlayerRepository.searchValid](lib/data/player_repository.dart)
only ever returns players valid for BOTH factors, so anything the user can tap is
a legal answer. `PlayerRepository` is abstract, so the data source can be swapped
without touching UI. [player_attributes.dart](lib/data/player_attributes.dart) is
a curated **local cache** that guarantees offline board solvability (see below).

### Factors & board generation
[game/xox/factor.dart](lib/game/xox/factor.dart) — a `Factor` has a `FactorType`
(playedLeague / wonLeague / wonInternational / team / nationality), a display
`label`, a canonical `value`, and a `matches(Player)` predicate. Equality is by
`(type, value)`.

[game/xox/factor_pool.dart](lib/game/xox/factor_pool.dart) holds the catalogue
(6 leagues × {played, won}, 3 international tournaments, 44 clubs, 59
nationalities) and `generateBoard()`, which returns 3 row + 3 column factors
that are **all six unique**, obey axis-exclusivity rules (`_axesAreValid`), and
are **fully solvable** — every one of the 9 cells has ≥1 player in the local
cache ([player_attributes.dart](lib/data/player_attributes.dart)) satisfying both
its factors, checked via [board_solver.dart](lib/game/xox/board_solver.dart).
The cache must stay non-empty or generation can't guarantee solvability.

## Extending

- **Wider board variety / solvability**: add `Player` entries to the local cache
  in [data/player_attributes.dart](lib/data/player_attributes.dart). League /
  title / team strings MUST match the canonical names in `FactorPool`. (Live
  search still finds anyone via Transfermarkt; the cache only seeds generation.)
- **New club / nationality**: add to the lists in `FactorPool`, then add the
  Transfermarkt name → canonical mappings in
  [transfermarkt_service.dart](lib/data/transfermarkt_service.dart)
  (`_teamAliases` + `_teamLeague`, or `_nationalityMap`).
- **Swap the data source**: implement `PlayerRepository` and inject it via
  `FootballXoxScreen(repository: ...)`.
- **New factor type**: add to `FactorType`, extend `Factor.matches`, emit it from
  `FactorPool.allFactors()`, and make `TransfermarktService` populate the
  matching `Player` field.
- **Verify against live data**: `dart run scratch/tm_test.dart` (needs the
  Transfermarkt service running) checks representative factor pairs end-to-end.

## Conventions

- `StatefulWidget` for game state (no state-management package).
- Use the shared `BrutalistCard` / `BrutalistButton` rather than re-styling
  containers; pull colours from `AppColors` and text styles from `AppTheme`.
- Grid/headers must scale to fit common phone sizes without overflow (the XOX
  board uses `LayoutBuilder` + `FittedBox`).
