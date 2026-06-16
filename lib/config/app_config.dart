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

  /// Google Gemini API key used by [AnswerSearchService] to fetch live
  /// reference answers for the party games. Provide it via:
  ///
  /// ```
  /// flutter run --dart-define=GEMINI_API_KEY=<your-key>
  /// ```
  ///
  /// When empty, the party games fall back to the offline local corpus.
  ///
  /// NOTE: a `--dart-define` key is compiled into the binary and can be
  /// extracted — fine for local/personal dev, but a public release should move
  /// the key behind a proxy server.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Whether a Gemini API key is configured.
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
