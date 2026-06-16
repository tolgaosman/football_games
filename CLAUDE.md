# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Flyball** — a Flutter mobile app of football trivia mini-games with a Dark-Mode
Neo-Brutalist aesthetic (deep charcoal `#121212`, neon "Pitch Green" `#39FF14`,
sharp white; thick borders, hard un-blurred drop shadows, blocky corners,
Space Grotesk via `google_fonts`).

Three games exist; only the first is fully implemented:
- **Football XOX** — fully built. A 3×3 trivia grid; each row/column gets a
  random unique factor (category). **Currently in Game Master Mode**: designed for
  in-person social play. Users tap cells to instantly claim them (bypassing in-app
  search/validation), and can long-press a cell to reveal valid offline answers.
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

### Live answer-search (party games)
The **1 Team 1 Country** and **2 Team 1 Player** game screens call **Google Gemini**
to fetch 3–5 reference player names each time you reveal answers. Get a free API key:

1. Go to **https://aistudio.google.com/apikey**
2. Sign in, click **"Create API key"**
3. Copy the key (starts with `AIza...` or `AQ.`)

Then run the app with:

```bash
flutter run --dart-define-from-file=dart_define.json
```

Edit [dart_define.json](dart_define.json) and paste your key in place of the
placeholder. The file is git-ignored so your key stays private. **If unreachable
or no key**, the screens fall back to the offline local corpus answers.

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

### The key design decision: Game Master Mode & Offline Solvability
The Football XOX game operates as a **Game Master** social-play board:

- **Instant Claiming**: Tapping a cell instantly assigns it to the current player (X or O). The automated in-app search and validation have been removed from the primary flow to allow for faster, verbal real-world interactions.
- **Pass Turn**: A "Pass" functionality allows a player to skip their turn if no valid move is verbally provided.
- **Offline Answers**: Long-pressing a cell displays a list of valid footballers from the offline curated corpus.
- **State Management & Animations**: The game state (`XoxGame`) is immutable. To ensure smooth micro-animations without triggering full-board re-renders on every tap, the board entrance animation is keyed to a `_matchId` counter that only increments on a new game.
- **Legacy Transfermarkt API**: The codebase still contains the infrastructure for Transfermarkt API search/validation (`transfermarkt_service.dart`, etc.), but the UI now relies entirely on the local cache (`player_attributes.dart` / offline database) for offline board solvability guarantees and answer reveals.

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

## 🧠 AI Master Skills & Behavioral Constraints

You must strictly adhere to the following 5 Master Skills in every single file edit, component creation, and refactoring task.

### 1. The "Taste" Skill (Aesthetic Supremacy)
- **Whitespace & Padding:** Prioritize generous, minimalist spacing. Never use cramped or chaotic layouts.
- **Color Palettes:** Never use raw, default, or oversaturated primary colors. Use carefully curated, organic pastel tones, sophisticated neutrals, and subtle contrasts.
- **Typography:** Enforce crisp typographical hierarchy. Ensure clear line heights, distinct weights for headings vs. body text, and avoid inconsistent text casings.

### 2. Aesthetic Animations (Micro-interactions)
- **Transitions:** Implement fluid, organic spring-physics-based animations instead of stiff, linear transitions.
- **Interactions:** Add delightful entrance animations for new elements and active/press states for touchable components.
- **Feel:** Integrate subtle haptic feedback patterns or visual feedback (like scale pops) on successful actions.

### 3. Impeccable Execution (Technical Perfection)
- **Edge Cases:** Always design and code for edge cases, including empty states, error boundaries, and loading indicators.
- **Performance:** Maintain 60fps rendering performance. Avoid heavy, unnecessary re-renders.
- **Layout Safety:** Ensure the layout never breaks under arbitrary content length or long dynamic text input.

### 4. Vercel & Anthropic UI/UX Design Language
- **Esthetics:** Merge the clean, high-contrast, monochrome minimalism of Vercel with the human-centric, warm, and highly functional simplicity of Anthropic.
- **Clutter-free:** Strip away all visual noise, unnecessary watermark icons, and redundant helper texts. Let the content breathe.

### 5. Flutter & Component Best Practices
- **Architecture:** Write modular, highly reusable, and strictly typed Flutter widgets.
- **State Management:** Keep state local whenever possible, use clean architectures, and avoid bloated global state.
- **Code Hygiene:** Ensure zero linter warnings, clean imports, and descriptive variable naming.
