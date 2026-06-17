import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// The outcome of a live answer search: the [players] plus a [verified] flag
/// telling the UI whether they survived the strict verification pass.
///
/// [verified] is `true` for a normal two-phase success (recall → verify) and
/// for the curated local corpus (which the caller trusts). It is `false` only
/// when the verification call itself failed and we fell back to the raw,
/// unchecked recall candidates — letting the UI warn the user that the list was
/// not fact-checked.
@immutable
class AnswerResult {
  const AnswerResult(this.players, {required this.verified});

  final List<String> players;
  final bool verified;
}

/// Fetches live **reference answers** for a party-game round from Google Gemini.
///
/// Given two category conditions (e.g. `"Chelsea"` + `"Brazil"`, or two club
/// names), it returns every real footballer that satisfies BOTH — aiming for
/// **maximum coverage with zero hallucinations**. It does this in two grounded
/// passes:
///
///   1. **Recall** — ask for a deliberately generous candidate list, telling the
///      model NOT to filter (so it never self-censors correct-but-uncertain
///      names; this is what fixes "only one player came back").
///   2. **Verify** — feed that candidate list back and keep ONLY the names the
///      model can confirm from sources for both conditions (this is what drops
///      hallucinations like a player listed for a club they never played for).
///
/// This supplements the finite on-device corpus: the screens call it when
/// revealing answers and fall back to the local corpus when it returns `null`
/// (no proxy configured, no network, timeout, or an unparseable recall
/// response).
///
/// SECURITY: this talks to a small **backend proxy** ([AppConfig.proxyBaseUrl]),
/// never to Gemini directly. The Gemini API key lives only on the proxy, so it
/// is never compiled into the app binary where it could be extracted. The proxy
/// is a thin pass-through: the app sends a prompt plus thinking/output budgets,
/// the proxy injects the key + Google Search tool and returns Gemini's response
/// body verbatim (so the parsing below is unchanged).
///
/// No caching — every reveal triggers a fresh request. All failures are
/// swallowed and surfaced as `null`; this never throws to the UI.
class AnswerSearchService {
  AnswerSearchService({http.Client? client, String? proxyBaseUrl})
      : _client = client ?? http.Client(),
        _proxyBaseUrl = proxyBaseUrl ?? AppConfig.proxyBaseUrl;

  final http.Client _client;
  final String _proxyBaseUrl;

  static const _timeout = Duration(seconds: 15);

  /// Returns the players satisfying BOTH [condition1] and [condition2], or
  /// `null` on a recall failure (caller uses the local fallback).
  ///
  /// NOTE: this makes TWO sequential Gemini calls (recall, then verify), so the
  /// worst-case latency is ~2× a single call (each capped at [_timeout]). The
  /// answers dialog shows a spinner for the whole future, so this is acceptable.
  Future<AnswerResult?> search({
    required String condition1,
    required String condition2,
  }) async {
    if (_proxyBaseUrl.isEmpty) return null;

    // PHASE 1 — RECALL: cast a wide net. `null` (transport/parse failure) or an
    // empty list (model found nobody) both mean we have nothing to verify, so
    // fall straight back to the curated local corpus.
    final candidates = await _recall(condition1, condition2);
    if (candidates == null || candidates.isEmpty) return null;

    // PHASE 2 — VERIFY: strictly confirm each candidate against grounded
    // sources.
    final verified = await _verify(candidates, condition1, condition2);

    // A non-empty verified list is the clean, fact-checked result.
    if (verified != null && verified.isNotEmpty) {
      return AnswerResult(verified, verified: true);
    }

    // An EMPTY (but successful) verify response means the model rejected every
    // candidate — none could be confirmed for both conditions. Surfacing the
    // unverified recall list here would defeat the zero-hallucination goal, so
    // fall back to the curated local corpus instead.
    if (verified != null) return null;

    // `verified == null` means the verification CALL itself failed
    // (network/timeout/parse). Per product decision we still surface the broad
    // recall list for maximum coverage, but flag it UNVERIFIED so the UI can
    // warn that these names were not fact-checked.
    return AnswerResult(candidates, verified: false);
  }

  /// PHASE 1: a generous candidate list. Lower thinking (brainstorming is
  /// shallow) leaves more of the 8192-token budget for a long list.
  Future<List<String>?> _recall(String condition1, String condition2) {
    return _postPrompt(
      _recallPrompt(condition1, condition2),
      thinkingBudget: 512,
      maxOutputTokens: 8192,
    );
  }

  /// PHASE 2: strict verification of [candidates]. Higher thinking gives the
  /// model room to cross-check each name; the output is a subset of the input,
  /// so a smaller output budget is plenty and lowers the truncation risk.
  Future<List<String>?> _verify(
    List<String> candidates,
    String condition1,
    String condition2,
  ) {
    return _postPrompt(
      _verifyPrompt(candidates, condition1, condition2),
      thinkingBudget: 2048,
      maxOutputTokens: 4096,
    );
  }

  /// Runs one grounded answer search with [prompt] and the given thinking/output
  /// budgets, returning the parsed player names or `null` on any failure (non-200,
  /// timeout, malformed/empty/MAX_TOKENS body, exception).
  ///
  /// The request goes to the backend proxy (`POST $proxyBaseUrl/answers`), which
  /// holds the Gemini key, attaches the Google Search grounding tool, and returns
  /// Gemini's response body verbatim. Keeping the key server-side is what stops it
  /// being extracted from the app binary. Shared by both phases so request
  /// building, the [_timeout] and the `MAX_TOKENS` guard live in one place.
  Future<List<String>?> _postPrompt(
    String prompt, {
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    // Trim a trailing slash so '$base/answers' is well-formed for either form.
    final base = _proxyBaseUrl.endsWith('/')
        ? _proxyBaseUrl.substring(0, _proxyBaseUrl.length - 1)
        : _proxyBaseUrl;
    final uri = Uri.parse('$base/answers');

    // The proxy injects the Gemini URL/key and the Google Search grounding tool;
    // we only send the prompt plus the per-phase thinking/output budgets.
    final body = jsonEncode({
      'prompt': prompt,
      'thinkingBudget': thinkingBudget,
      'maxOutputTokens': maxOutputTokens,
    });

    try {
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
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

  /// PHASE 1 prompt — wide recall. Explicitly tells the model to over-include
  /// and NOT filter, so it never drops a correct-but-uncertain name (a later
  /// pass removes the wrong ones).
  String _recallPrompt(String condition1, String condition2) {
    return 'Act as an expert football researcher building a CANDIDATE list. '
        'Your ONLY job right now is RECALL, not verification. List every '
        'real-life footballer who MIGHT satisfy BOTH of these conditions:\n'
        '1. "$condition1"\n'
        '2. "$condition2"\n\n'
        'RULES:\n'
        '- USE WEB SEARCH and think broadly. Include well-known players, '
        'lesser-known ones, retired ones, and anyone you are even reasonably '
        'unsure about. OVER-INCLUDE on purpose.\n'
        '- Do NOT filter, drop, or self-censor names at this stage. A separate '
        'verification step will remove the wrong ones later, so it is far better '
        'to list a borderline name than to omit a correct one.\n'
        '- Only requirement: each name must be a real footballer who plausibly '
        'has some connection to BOTH conditions. Do not invent people.\n'
        '- A condition naming a tournament (e.g. "Champions League", "World '
        'Cup") refers to a player who WON it.\n'
        '- Respond with ONLY raw JSON, no markdown fences and no commentary, in '
        'exactly this shape: {"players": ["Full Name", "Full Name"]}.';
  }

  /// PHASE 2 prompt — strict verification. Takes the recall [candidates] as
  /// input and keeps only the names confirmed for BOTH conditions.
  String _verifyPrompt(
    List<String> candidates,
    String condition1,
    String condition2,
  ) {
    // Encode the candidate list as a JSON array so it is unambiguous to the
    // model and impossible to confuse with prose.
    final list = jsonEncode(candidates);
    return 'Act as a strict football fact-checker. Below is a CANDIDATE list of '
        'footballers. For EACH name, use WEB SEARCH to confirm whether that '
        'exact player genuinely satisfies BOTH conditions:\n'
        '1. "$condition1"\n'
        '2. "$condition2"\n\n'
        'CANDIDATES: $list\n\n'
        'RULES:\n'
        '- KEEP a name ONLY if sources confirm a real competitive spell for '
        'BOTH conditions (not a rumour, a loan that fell through, a youth-only '
        'stint, or a different player with a similar name).\n'
        '- DROP every name you cannot confirm for BOTH. When in doubt, leave it '
        'out — accuracy matters more than length, and the list must contain ZERO '
        'wrong names.\n'
        '- Do NOT add any new names that are not in the candidate list.\n'
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
  /// Returns `null` if no usable `{"players": [...]}` can be recovered (no
  /// candidates / wrong shape / truncated / missing key). A present-but-empty
  /// `players` array returns an empty list, NOT `null`, so a caller can tell a
  /// successful "found/confirmed nobody" apart from a failed request.
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

    // Return every valid name (no upper cap). A present-but-empty `players`
    // array yields an empty list (a valid "nobody" answer), distinct from the
    // `null`s above which signal an unusable/failed response.
    return players
        .whereType<String>()
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
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
