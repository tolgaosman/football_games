import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flyball/data/answer_search_service.dart';

/// Wraps [players] in the Gemini `generateContent` response envelope, with the
/// inner `{"players": [...]}` JSON serialised into the part's `text` field.
String _geminiResponse(List<String> players) {
  return jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {
              'text': jsonEncode({'players': players}),
            },
          ],
        },
      },
    ],
  });
}

/// A client that returns the SAME [players] for BOTH the recall and verify
/// calls — i.e. the verify pass confirms every recall candidate. Used wherever
/// the final verified list should equal the model's list.
http.Client _okClient(List<String> players) {
  return MockClient((_) async => http.Response(_geminiResponse(players), 200));
}

/// Returns [recall] for the first call and [verify] for the second, so a test
/// can drive the two-phase flow independently.
http.Client _twoPhaseClient(http.Response recall, http.Response verify) {
  var call = 0;
  return MockClient((_) async => (call++ == 0) ? recall : verify);
}

/// Wraps an arbitrary [text] string as the model's single text part (used to
/// test parsing of markdown fences / prose around the JSON).
String _rawText(String text) {
  return jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  });
}

void main() {
  group('AnswerSearchService', () {
    test('parses a well-formed response into a name list', () async {
      // _okClient answers both phases, so verify echoes recall.
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _okClient(['Zinedine Zidane', 'Karim Benzema', 'Raphaël Varane']),
      );
      final result = await service.search(
        condition1: 'Real Madrid',
        condition2: 'France',
      );
      expect(result?.players,
          ['Zinedine Zidane', 'Karim Benzema', 'Raphaël Varane']);
      expect(result?.verified, isTrue);
    });

    test('returns every name with no upper cap', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _okClient(['A', 'B', 'C', 'D', 'E', 'F', 'G']),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
    });

    test('drops blank names but keeps the valid ones', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _okClient(['Solo', '', '   ', 'Duo']),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['Solo', 'Duo']);
    });

    test('makes two calls: recall then verify', () async {
      final bodies = <String>[];
      var calls = 0;
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((request) async {
          calls++;
          bodies.add(request.body);
          return http.Response(_geminiResponse(['Steven Gerrard']), 200);
        }),
      );
      await service.search(condition1: 'Liverpool', condition2: 'England');
      expect(calls, 2);
      // First call is the wide recall prompt.
      expect(bodies[0], contains('OVER-INCLUDE'));
      // Second call is the strict verify prompt, carrying the recall candidates.
      expect(bodies[1], contains('CANDIDATES:'));
      expect(bodies[1], contains('Steven Gerrard'));
    });

    test('verify narrows the recall list', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _twoPhaseClient(
          http.Response(_geminiResponse(['A', 'B', 'C', 'D']), 200),
          http.Response(_geminiResponse(['A', 'C']), 200),
        ),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['A', 'C']);
      expect(result?.verified, isTrue);
    });

    test('returns null and skips verify when recall fails', () async {
      var calls = 0;
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async {
          calls++;
          return http.Response('nope', 500);
        }),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
      // Verify must NOT run when there are no candidates.
      expect(calls, 1);
    });

    test('returns the unverified recall list when verify fails', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _twoPhaseClient(
          http.Response(_geminiResponse(['A', 'B', 'C']), 200),
          http.Response('boom', 500),
        ),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['A', 'B', 'C']);
      expect(result?.verified, isFalse);
    });

    test('returns null when verify rejects every candidate', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: _twoPhaseClient(
          http.Response(_geminiResponse(['A', 'B']), 200),
          http.Response(_geminiResponse(const []), 200),
        ),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('extracts JSON from a markdown code fence', () async {
      final fenced =
          '```json\n{"players": ["Steven Gerrard", "Jamie Carragher"]}\n```';
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response(_rawText(fenced), 200)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['Steven Gerrard', 'Jamie Carragher']);
    });

    test('extracts JSON from surrounding prose', () async {
      final prose =
          'Here are the players I found: {"players": ["James Milner"]} -- hope it helps!';
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response(_rawText(prose), 200)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['James Milner']);
    });

    test('stitches text across multiple parts', () async {
      final body = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '{"players": ["Philippe '},
                {'text': 'Coutinho", "Christian Benteke"]}'},
              ],
            },
          },
        ],
      });
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result?.players, ['Philippe Coutinho', 'Christian Benteke']);
    });

    test('posts to the proxy /answers endpoint, never to Gemini directly',
        () async {
      final urls = <String>[];
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((request) async {
          urls.add(request.url.toString());
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      await service.search(condition1: 'X', condition2: 'Y');
      expect(urls, isNotEmpty);
      // The Gemini key/URL live only on the proxy: the app must hit the proxy
      // and must never call generativelanguage.googleapis.com itself.
      expect(urls.every((u) => u == 'https://proxy.test/answers'), isTrue);
      expect(urls.any((u) => u.contains('googleapis.com')), isFalse);
    });

    test('sends a thinking budget on both calls', () async {
      final bodies = <String>[];
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((request) async {
          bodies.add(request.body);
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      await service.search(condition1: 'X', condition2: 'Y');
      expect(bodies.every((b) => b.contains('thinkingBudget')), isTrue);
    });

    test('returns null when the recall response is truncated (MAX_TOKENS)',
        () async {
      // The recall call hit the token limit mid-answer; we must discard it so
      // the caller falls back instead of verifying a clipped list.
      final body = jsonEncode({
        'candidates': [
          {
            'finishReason': 'MAX_TOKENS',
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'players': ['Christian Benteke'],
                  }),
                },
              ],
            },
          },
        ],
      });
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('returns null on a non-200 recall response', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('returns null on a malformed recall body', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async => http.Response('not json', 200)),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('returns null when the players key is missing', () async {
      final service = AnswerSearchService(
        proxyBaseUrl: 'https://proxy.test',
        client: MockClient((_) async {
          final body = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({'foo': 'bar'}),
                    },
                  ],
                },
              },
            ],
          });
          return http.Response(body, 200);
        }),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('returns null and makes no request when no proxy is configured',
        () async {
      var called = false;
      final service = AnswerSearchService(
        proxyBaseUrl: '',
        client: MockClient((_) async {
          called = true;
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      final result = await service.search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
      expect(called, isFalse);
    });
  });
}
