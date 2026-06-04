import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flyball/data/transfermarkt_service.dart';
import 'package:flyball/game/xox/factor.dart';

/// Canned responses matching the felipeall/transfermarkt-api JSON contract.
/// Models Lionel Messi: Argentina, Barcelona + PSG, La Liga + Ligue 1 titles,
/// World Cup + Copa America wins.
http.Client _messiClient() {
  return MockClient((request) async {
    final path = request.url.path;
    Map<String, dynamic> body;

    if (path.contains('/search/')) {
      body = {
        'query': 'messi',
        'pageNumber': 1,
        'lastPageNumber': 1,
        'results': [
          {
            'id': '28003',
            'name': 'Lionel Messi',
            'position': 'Right Winger',
            'club': {'name': 'Inter Miami', 'id': '69261'},
            'age': 38,
            'nationalities': ['Argentina'],
            'marketValue': 18000000,
          },
        ],
      };
    } else if (path.endsWith('/profile')) {
      body = {
        'id': '28003',
        'name': 'Lionel Messi',
        'imageUrl': 'https://img.example/messi.png',
        'citizenship': ['Argentina', 'Spain'],
        'isRetired': false,
      };
    } else if (path.endsWith('/transfers')) {
      body = {
        'id': '28003',
        'transfers': [
          {
            'id': '1',
            'clubFrom': {'id': '131', 'name': 'FC Barcelona'},
            'clubTo': {'id': '583', 'name': 'Paris Saint-Germain'},
            'date': 'Aug 10, 2021',
            'season': '21/22',
            'marketValue': 80000000,
            'fee': 'free transfer',
          },
        ],
        'youthClubs': ['Newell\'s Old Boys', 'FC Barcelona'],
      };
    } else if (path.endsWith('/achievements')) {
      body = {
        'id': '28003',
        'achievements': [
          {
            'title': 'World Cup winner',
            'count': 1,
            'details': [
              {'season': {'id': '2022', 'name': '2022'}},
            ],
          },
          {
            'title': 'Copa América winner',
            'count': 1,
            'details': [
              {'season': {'id': '2021', 'name': '2021'}},
            ],
          },
          {
            'title': 'Spanish champion',
            'count': 10,
            'details': [
              {
                'season': {'id': '2018', 'name': '18/19'},
                'competition': {'id': 'ES1', 'name': 'LaLiga'},
                'club': {'id': '131', 'name': 'FC Barcelona'},
              },
            ],
          },
          {
            'title': 'French champion',
            'count': 1,
            'details': [
              {
                'season': {'id': '2021', 'name': '21/22'},
                'competition': {'id': 'FR1', 'name': 'Ligue 1'},
                'club': {'id': '583', 'name': 'Paris Saint-Germain'},
              },
            ],
          },
        ],
      };
    } else {
      body = {};
    }
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
}

/// Models an academy / one-club player like Lamine Yamal: NO senior transfers
/// (empty transfers list), current club only in the profile, La Liga title and
/// a "European champion" (Euros) win. This is the case that previously failed
/// "Played in La Liga" because leaguesPlayed was derived solely from transfers.
http.Client _academyClient() {
  return MockClient((request) async {
    final path = request.url.path;
    Map<String, dynamic> body;

    if (path.contains('/search/')) {
      body = {
        'query': 'lamine',
        'results': [
          {
            'id': '937958',
            'name': 'Lamine Yamal',
            'club': {'name': 'FC Barcelona', 'id': '131'},
            'nationalities': ['Spain'],
          },
        ],
      };
    } else if (path.endsWith('/profile')) {
      body = {
        'id': '937958',
        'name': 'Lamine Yamal',
        'citizenship': ['Spain'],
        'club': {
          'id': '131',
          'name': 'FC Barcelona',
          'mostGamesFor': 'FC Barcelona',
          'lastClubName': null,
        },
        'isRetired': false,
      };
    } else if (path.endsWith('/transfers')) {
      // No senior transfers.
      body = {'id': '937958', 'transfers': [], 'youthClubs': []};
    } else if (path.endsWith('/achievements')) {
      body = {
        'id': '937958',
        'achievements': [
          {
            'title': 'European champion',
            'count': 1,
            'details': [
              {'season': {'id': '2024', 'name': '2024'}},
            ],
          },
          {
            'title': 'Spanish champion',
            'count': 1,
            'details': [
              {
                'season': {'id': '2024', 'name': '24/25'},
                'competition': {'id': 'ES1', 'name': 'LaLiga'},
                'club': {'id': '131', 'name': 'FC Barcelona'},
              },
            ],
          },
        ],
      };
    } else {
      body = {};
    }
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
}

void main() {
  group('TransfermarktService enrichment', () {
    test('maps nationality, clubs, league titles and international wins', () async {
      final tm = TransfermarktService(
          client: _messiClient(), baseUrl: 'http://test');

      // A permissive pair Messi satisfies, so the enriched player comes back.
      final players = await tm.searchAndValidate(
        query: 'messi',
        rowFactor: const Factor(
            type: FactorType.nationality, label: 'Argentina', value: 'Argentina'),
        columnFactor: const Factor(
            type: FactorType.playedLeague, label: 'La Liga', value: 'La Liga'),
      );

      expect(players, hasLength(1));
      final p = players.single;
      expect(p.name, 'Lionel Messi');
      expect(p.nationality, 'Argentina');
      expect(p.teams, containsAll(<String>{'Barcelona', 'PSG'}));
      expect(p.leagueTitles, containsAll(<String>{'La Liga', 'Ligue 1'}));
      expect(p.internationalTitles,
          containsAll(<String>{'World Cup', 'Copa America'}));
      // Played-leagues inferred from clubs in the FactorPool team list.
      expect(p.leaguesPlayed, containsAll(<String>{'La Liga', 'Ligue 1'}));
    });

    test('filters out players who do not satisfy both factors', () async {
      final tm = TransfermarktService(
          client: _messiClient(), baseUrl: 'http://test');

      // Messi never won the Premier League → no match for this pair.
      final players = await tm.searchAndValidate(
        query: 'messi',
        rowFactor: const Factor(
            type: FactorType.wonLeague,
            label: 'Won Premier League',
            value: 'Premier League'),
        columnFactor: const Factor(
            type: FactorType.nationality, label: 'Argentina', value: 'Argentina'),
      );
      expect(players, isEmpty);
    });

    test('respects excludeIds', () async {
      final tm = TransfermarktService(
          client: _messiClient(), baseUrl: 'http://test');
      final players = await tm.searchAndValidate(
        query: 'messi',
        rowFactor: const Factor(
            type: FactorType.nationality, label: 'Argentina', value: 'Argentina'),
        columnFactor: const Factor(
            type: FactorType.playedLeague, label: 'La Liga', value: 'La Liga'),
        excludeIds: {'tm-28003'},
      );
      expect(players, isEmpty);
    });
  });

  group('TransfermarktService one-club / academy players', () {
    test('derives team & league from profile.club when transfers are empty',
        () async {
      final tm = TransfermarktService(
          client: _academyClient(), baseUrl: 'http://test');

      // The exact failing case from the report: Won Euros × Played in La Liga.
      final players = await tm.searchAndValidate(
        query: 'lamine',
        rowFactor: const Factor(
            type: FactorType.wonInternational, label: 'Won Euros', value: 'Euros'),
        columnFactor: const Factor(
            type: FactorType.playedLeague,
            label: 'Played in La Liga',
            value: 'La Liga'),
      );

      expect(players, hasLength(1));
      final p = players.single;
      expect(p.name, 'Lamine Yamal');
      expect(p.nationality, 'Spain');
      expect(p.teams, contains('Barcelona'));
      // Played-league comes from the profile club (no transfers) AND the title.
      expect(p.leaguesPlayed, contains('La Liga'));
      expect(p.leagueTitles, contains('La Liga'));
      expect(p.internationalTitles, contains('Euros'));
    });
  });
}
