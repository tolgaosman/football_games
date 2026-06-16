import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Fetches live **reference answers** for a party-game round from Google Gemini.
///
/// Given two category conditions (e.g. `"Chelsea"` + `"Brazil"`, or two club
/// names), it asks Gemini for **all** real footballers it can recall who satisfy
/// BOTH, returning their names. This supplements the finite on-device corpus:
/// the screens call it when revealing answers and fall back to the local corpus
/// when it returns `null` (no key, no network, timeout, or an unparseable
/// response).
///
/// No caching — every reveal triggers a fresh request. All failures are
/// swallowed and surfaced as `null`; this never throws to the UI.
class AnswerSearchService {
  AnswerSearchService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? AppConfig.geminiApiKey;

  final http.Client _client;
  final String _apiKey;

  static const _model = 'gemini-2.5-flash';
  static const _timeout = Duration(seconds: 15);

  /// Returns all player names Gemini recalls satisfying BOTH [condition1] and
  /// [condition2], or `null` on any failure (caller uses the local fallback).
  Future<List<String>?> search({
    required String condition1,
    required String condition2,
  }) async {
    if (_apiKey.isEmpty) return null;

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent',
    );

    // Google Search grounding lets the model cross-check real transfer/career
    // data instead of relying on memory alone, giving far more complete lists.
    // NOTE: `responseMimeType: application/json` cannot be combined with the
    // search tool, so we drop it and parse JSON out of the free-text response.
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt(condition1, condition2)},
          ],
        },
      ],
      'tools': [
        {'google_search': <String, dynamic>{}},
      ],
      'generationConfig': {
        'temperature': 0.2,
        // gemini-2.5-flash is a hybrid "thinking" model. Left unset it spends a
        // large, variable share of the output budget on hidden reasoning, which
        // truncates the answer; capped too low (e.g. 128) it has no room to
        // cross-check each candidate against the grounded sources and starts
        // hallucinating (listing players who only played for one of the clubs).
        // 1024 leaves it room to verify each name while keeping plenty of the
        // 8192 budget for the actual list.
        'thinkingConfig': {'thinkingBudget': 1024},
        'maxOutputTokens': 8192,
      },
    });

    try {
      // The key is sent via the `x-goog-api-key` header, which works for both
      // the classic `AIza...` API keys and the newer `AQ.` auth keys.
      final res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(_timeout);
      if (kDebugMode) {
        debugPrint('[AnswerSearch] status=${res.statusCode} body=${res.body}');
      }
      if (res.statusCode != 200) return null;
      final names = _parse(res.body);
      if (kDebugMode) {
        debugPrint('[AnswerSearch] parsed ${names?.length ?? 0} names: $names');
      }
      return names;
    } catch (e) {
      if (kDebugMode) debugPrint('[AnswerSearch] error: $e');
      return null;
    }
  }

  /// The strict football-historian prompt, asking for a fixed JSON shape we
  /// control (`{"players": [...]}`) so parsing is robust.
  String _prompt(String condition1, String condition2) {
    return 'Act as an expert football historian. List EVERY real-life footballer '
        'who satisfies BOTH of these conditions:\n'
        '1. "$condition1"\n'
        '2. "$condition2"\n\n'
        'STRICT RULES:\n'
        '- USE WEB SEARCH to find as many qualifying players as possible. '
        'Cross-check players\' full career and transfer histories so you do not '
        'miss lesser-known or retired ones. The goal is the COMPLETE list.\n'
        '- VERIFY EVERY NAME before adding it: confirm from the sources that the '
        'player actually played for BOTH clubs/teams (a real competitive spell, '
        'not a rumour, loan that fell through, youth-only stint, or a similarly '
        'named different player). For each candidate, mentally check "did they '
        'truly appear for $condition1 AND for $condition2?" and DROP any you '
        'cannot confirm for both.\n'
        '- NO HALLUCINATIONS: accuracy is more important than length. A shorter '
        'list of certain names is far better than a longer one with a single '
        'wrong name. When in doubt, leave it out.\n'
        '- A condition naming a tournament (e.g. "Champions League", "World '
        'Cup") means the player WON it.\n'
        '- Respond with ONLY raw JSON, no markdown fences and no commentary, in '
        'exactly this shape: {"players": ["Full Name", "Full Name"]}.';
  }

  /// Extracts the player names from a Gemini `generateContent` response.
  ///
  /// With Google Search grounding the model returns free text (no enforced JSON
  /// mime type), possibly across multiple `parts` and wrapped in markdown or
  /// prose, so we concatenate all text parts and pull the JSON object out of it.
  /// Returns `null` if no usable `{"players": [...]}` can be recovered.
  List<String>? _parse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) return null;

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    // A truncated answer (hit the token limit) yields a partial/invalid list —
    // discard it and let the caller fall back rather than show a clipped result.
    if (first['finishReason'] == 'MAX_TOKENS') return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    // Grounded answers can span several parts; stitch their text together.
    final text = parts
        .whereType<Map>()
        .map((p) => p['text'])
        .whereType<String>()
        .join();
    if (text.isEmpty) return null;

    final inner = _extractJsonObject(text);
    if (inner == null) return null;
    final players = inner['players'];
    if (players is! List) return null;

    final names = players
        .whereType<String>()
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    // Return every valid name (no upper cap); only an empty list is a failure.
    return names.isEmpty ? null : names;
  }

  /// Recovers the first JSON object embedded in [text], tolerating markdown
  /// code fences and surrounding prose by slicing from the first `{` to the
  /// last `}`. Returns `null` if that span does not decode to a JSON map.
  Map<String, dynamic>? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
