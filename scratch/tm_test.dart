// Live end-to-end check of the Transfermarkt data layer.
//
// Requires the self-hosted transfermarkt-api running and reachable:
//   docker run -p 8000:8000 transfermarkt-api
//
// Run (defaults to http://localhost:8000):
//   dart run scratch/tm_test.dart
//   dart run scratch/tm_test.dart http://localhost:8000
//
// It searches + enriches a few well-known players and prints the canonical
// attributes the game will validate against, then checks representative factor
// pairs. Use this to confirm name-mapping (nationality / clubs / trophies)
// before trusting in-app results.

// ignore_for_file: avoid_print

import 'package:flyball/data/transfermarkt_service.dart';
import 'package:flyball/game/xox/factor.dart';

Future<void> main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args.first : null;
  final tm = TransfermarktService(baseUrl: baseUrl);

  // ── Representative factor pairs (should return the right player) ──
  final cases = <String, List<Factor>>{
    'Messi': [
      const Factor(
          type: FactorType.nationality, label: 'Argentina', value: 'Argentina'),
      const Factor(
          type: FactorType.playedLeague, label: 'La Liga', value: 'La Liga'),
    ],
    'Ronaldo': [
      const Factor(
          type: FactorType.team, label: 'Real Madrid', value: 'Real Madrid'),
      const Factor(
          type: FactorType.wonInternational, label: 'Euros', value: 'Euros'),
    ],
    'Kane': [
      const Factor(
          type: FactorType.playedLeague,
          label: 'Premier League',
          value: 'Premier League'),
      const Factor(
          type: FactorType.nationality, label: 'England', value: 'England'),
    ],
    'Lewandowski': [
      const Factor(
          type: FactorType.wonLeague, label: 'Won Bundesliga', value: 'Bundesliga'),
      const Factor(
          type: FactorType.nationality, label: 'Poland', value: 'Poland'),
    ],
  };

  for (final entry in cases.entries) {
    final query = entry.key;
    final row = entry.value[0];
    final col = entry.value[1];
    print('\n=== "$query"  [$row] × [$col] ===');
    final players = await tm.searchAndValidate(
      query: query,
      rowFactor: row,
      columnFactor: col,
    );
    print('  matched: ${players.length}');
    for (final p in players) {
      print('    ${p.name} | nat=${p.nationality} | leagues=${p.leaguesPlayed} '
          '| titles=${p.leagueTitles} | teams=${p.teams} | intl=${p.internationalTitles}');
    }
  }
}
