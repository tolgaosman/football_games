/// App-wide runtime configuration.
///
/// Player data is sourced from a self-hosted Transfermarkt API whose base URL
/// is read from a compile-time environment value (see [transfermarktBaseUrl]).
class AppConfig {
  AppConfig._();

  /// Base URL of the self-hosted Transfermarkt API
  /// (https://github.com/felipeall/transfermarkt-api), the primary source for
  /// player nationality, clubs and trophies. Run it locally with
  /// `docker run -p 8000:8000 transfermarkt-api`, then provide the URL via:
  ///
  /// ```
  /// flutter run --dart-define=TRANSFERMARKT_BASE_URL=http://10.0.2.2:8000
  /// ```
  ///
  /// (Use `10.0.2.2` from an Android emulator to reach the host's localhost.)
  static const String transfermarktBaseUrl = String.fromEnvironment(
    'TRANSFERMARKT_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Base URL of the **answer-search proxy** used by [AnswerSearchService] to
  /// fetch live reference answers for the party games.
  ///
  /// This is NOT a secret — it is a public HTTPS endpoint that holds the Gemini
  /// API key server-side, so the key is never compiled into the app binary (where
  /// it could be extracted with `strings`). Provide it via:
  ///
  /// ```
  /// flutter run --dart-define=PROXY_BASE_URL=https://your-proxy.example.com
  /// ```
  ///
  /// When empty (no proxy configured), the party games fall back to the offline
  /// local corpus.
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: '',
  );

  /// Whether an answer-search proxy is configured.
  static bool get hasAnswerProxy => proxyBaseUrl.isNotEmpty;
}
