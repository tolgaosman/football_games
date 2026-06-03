/// App-wide runtime configuration.
///
/// The API-Football key is read from a compile-time environment value so it is
/// never committed to source. Provide it at run/build time, e.g.:
///
/// ```
/// flutter run --dart-define=API_FOOTBALL_KEY=your_key_here
/// ```
///
/// You can obtain a free key from https://www.api-football.com (direct
/// dashboard) — the free plan allows 100 requests/day. When the key is empty
/// the app stays fully navigable and the search sheet shows a clear
/// "add API key" state instead of crashing.
class AppConfig {
  AppConfig._();

  /// API-Football key, injected via --dart-define (empty when unset).
  static const String apiFootballKey =
      String.fromEnvironment('API_FOOTBALL_KEY', defaultValue: '');

  /// API-Football direct host. (If you instead use RapidAPI, swap this host
  /// and the auth header in [ApiFootballRepository].)
  static const String apiFootballHost = 'v3.football.api-sports.io';

  static bool get hasApiKey => apiFootballKey.trim().isNotEmpty;
}
