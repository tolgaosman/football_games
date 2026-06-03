import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/data/player.dart';
import 'package:flyball/game/xox/factor.dart';
import 'package:flyball/game/xox/factor_pool.dart';

void main() {
  group('FactorPool.generateBoard', () {
    test('returns 3 rows and 3 columns', () {
      final board = FactorPool.generateBoard(Random(1));
      expect(board.rows, hasLength(3));
      expect(board.columns, hasLength(3));
    });

    test('all six factors are unique across many seeds', () {
      for (var seed = 0; seed < 200; seed++) {
        final board = FactorPool.generateBoard(Random(seed));
        final all = {...board.rows, ...board.columns};
        expect(all, hasLength(6), reason: 'duplicate factor for seed $seed');
      }
    });

    test('is deterministic for a fixed seed', () {
      final a = FactorPool.generateBoard(Random(42));
      final b = FactorPool.generateBoard(Random(42));
      expect(a.rows, equals(b.rows));
      expect(a.columns, equals(b.columns));
    });

    test('exposes exactly 75 nationalities', () {
      expect(FactorPool.nationalities, hasLength(75));
    });
  });

  group('Factor.matches', () {
    final messi = const Player(
      id: 'messi',
      name: 'Lionel Messi',
      nationality: 'Argentina',
      leaguesPlayed: {'La Liga', 'Ligue 1'},
      leagueTitles: {'La Liga'},
      internationalTitles: {'World Cup'},
      teams: {'Barcelona'},
    );

    test('nationality factor matches', () {
      const f = Factor(
          type: FactorType.nationality, label: 'Argentina', value: 'Argentina');
      expect(f.matches(messi), isTrue);
    });

    test('played-league factor matches a league he played in', () {
      const f = Factor(
          type: FactorType.playedLeague,
          label: 'Played in La Liga',
          value: 'La Liga');
      expect(f.matches(messi), isTrue);
    });

    test('won-international factor matches', () {
      const f = Factor(
          type: FactorType.wonInternational,
          label: 'Won World Cup',
          value: 'World Cup');
      expect(f.matches(messi), isTrue);
    });

    test('rejects a league he never won', () {
      const f = Factor(
          type: FactorType.wonLeague,
          label: 'Won Premier League',
          value: 'Premier League');
      expect(f.matches(messi), isFalse);
    });
  });
}
