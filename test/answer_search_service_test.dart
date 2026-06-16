import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flyball/data/answer_search_service.dart';

/// Wraps [players] in the Gemini `generateContent` response envelope, with the
/// inner `{"players": [...]}` JSON serialised into the part's `text` field
/// (Gemini returns the model output as a string even with a JSON mime type).
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

http.Client _okClient(List<String> players) {
  return MockClient((_) async => http.Response(_geminiResponse(players), 200));
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
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: _okClient(['Zinedine Zidane', 'Karim Benzema', 'Raphaël Varane']),
      );
      final names = await service.search(
        condition1: 'Real Madrid',
        condition2: 'France',
      );
      expect(names, ['Zinedine Zidane', 'Karim Benzema', 'Raphaël Varane']);
    });

    test('returns every name with no upper cap', () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: _okClient(['A', 'B', 'C', 'D', 'E', 'F', 'G']),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
    });

    test('drops blank names but keeps the valid ones (even fewer than 5)',
        () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: _okClient(['Solo', '', '   ', 'Duo']),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, ['Solo', 'Duo']);
    });

    test('returns null when no valid names remain', () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: _okClient(['', '   ']),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
    });

    test('extracts JSON from a markdown code fence', () async {
      final fenced = '```json\n{"players": ["Steven Gerrard", "Jamie Carragher"]}\n```';
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(_rawText(fenced), 200)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, ['Steven Gerrard', 'Jamie Carragher']);
    });

    test('extracts JSON from surrounding prose', () async {
      final prose =
          'Here are the players I found: {"players": ["James Milner"]} -- hope it helps!';
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(_rawText(prose), 200)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, ['James Milner']);
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
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, ['Philippe Coutinho', 'Christian Benteke']);
    });

    test('sends a Google Search grounding tool in the request', () async {
      String? sentBody;
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sentBody = request.body;
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      await service.search(condition1: 'X', condition2: 'Y');
      expect(sentBody, contains('google_search'));
    });

    test('sends a low thinking budget in the request', () async {
      String? sentBody;
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sentBody = request.body;
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      await service.search(condition1: 'X', condition2: 'Y');
      expect(sentBody, contains('thinkingBudget'));
    });

    test('returns null on a truncated (MAX_TOKENS) response', () async {
      // The model hit the token limit mid-answer; even though the partial text
      // contains a parseable single-name object, we must discard it so the
      // caller falls back instead of showing a clipped list.
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
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
    });

    test('returns null on a non-200 response', () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
    });

    test('returns null on a malformed body', () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('not json', 200)),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
    });

    test('returns null when the players key is missing', () async {
      final service = AnswerSearchService(
        apiKey: 'test-key',
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
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
    });

    test('returns null and makes no request when the key is empty', () async {
      var called = false;
      final service = AnswerSearchService(
        apiKey: '',
        client: MockClient((_) async {
          called = true;
          return http.Response(_geminiResponse(['A', 'B', 'C']), 200);
        }),
      );
      final names = await service.search(condition1: 'X', condition2: 'Y');
      expect(names, isNull);
      expect(called, isFalse);
    });
  });
}
