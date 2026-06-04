import 'factor.dart';

/// How a [Factor] should be rendered as an image in headers/chips.
///
/// Exactly one of [networkUrl] / [assetPath] is non-null when an image is
/// available; both null means "no image — show the text label instead".
/// [isWonLeague] tells the renderer to stack a champion/#1 badge over a league
/// logo so "Won `<league>`" reads differently from "Played in `<league>`".
class FactorArt {
  const FactorArt({this.networkUrl, this.assetPath, this.isWonLeague = false});

  final String? networkUrl;
  final String? assetPath;
  final bool isWonLeague;

  bool get hasImage => networkUrl != null || assetPath != null;

  static const FactorArt none = FactorArt();
}

/// Resolves a [Factor] to its [FactorArt] (flag / league logo / team logo /
/// trophy asset). All maps are fixed and keyed by the canonical
/// `Factor.value` strings from `FactorPool`.
class FactorArtResolver {
  FactorArtResolver._();

  /// The club badge asset path for [team] (canonical club name), or null if the
  /// club has no logo. Exposes the private map for non-XOX features (e.g. the
  /// 2 Team 1 Player slots) without duplicating the asset table.
  static String? teamLogoAsset(String team) => _teamLogoAsset[team];

  /// The flag image URL for [nationality] (flagcdn.com), or null if the country
  /// has no mapping. Exposes the private map for non-XOX features (e.g. the
  /// 1 Team 1 Country slots).
  static String? countryFlagUrl(String nationality) {
    final iso = _countryIso2[nationality];
    return iso == null ? null : 'https://flagcdn.com/w160/$iso.png';
  }

  static FactorArt forFactor(Factor factor) {
    switch (factor.type) {
      case FactorType.nationality:
        // Flags stay on flagcdn.com — it is CORS-open so it works on web too.
        final iso = _countryIso2[factor.value];
        if (iso == null) return FactorArt.none;
        return FactorArt(networkUrl: 'https://flagcdn.com/w160/$iso.png');

      case FactorType.playedLeague:
        final asset = _leagueLogoAsset[factor.value];
        return asset == null ? FactorArt.none : FactorArt(assetPath: asset);

      case FactorType.wonLeague:
        final asset = _leagueLogoAsset[factor.value];
        return asset == null
            ? FactorArt.none
            : FactorArt(assetPath: asset, isWonLeague: true);

      case FactorType.team:
        final asset = _teamLogoAsset[factor.value];
        return asset == null ? FactorArt.none : FactorArt(assetPath: asset);

      case FactorType.wonInternational:
        final asset = _trophyAsset[factor.value];
        return asset == null ? FactorArt.none : FactorArt(assetPath: asset);
    }
  }

  /// International trophy images (supplied locally by the user).
  static const Map<String, String> _trophyAsset = {
    'World Cup': 'assets/images/worldCup.png',
    'Euros': 'assets/images/euros.png',
    'Copa America': 'assets/images/copaAmerica.png',
  };

  /// League badge asset paths (user-supplied), keyed by canonical league name.
  /// One badge per league subfolder.
  static const Map<String, String> _leagueLogoAsset = {
    'Premier League': 'assets/images/logos/epl/eplLogo.png',
    'La Liga': 'assets/images/logos/laLiga/laLigaLogo.png',
    'Serie A': 'assets/images/logos/serieA/serieALogo.png',
    'Bundesliga': 'assets/images/logos/bundesliga/bundesligaLogo.png',
    'Ligue 1': 'assets/images/logos/league1/ligue1Logo.png',
    'Trendyol Süper Lig': 'assets/images/logos/superLig/superLigLogo.png',
  };

  /// Club logo asset paths (user-supplied), keyed by canonical club name.
  /// Files live in per-league subfolders of `assets/images/logos/` with the
  /// user's abbreviated filenames.
  static const Map<String, String> _teamLogoAsset = {
    // Premier League
    'Arsenal': 'assets/images/logos/epl/arsenalLogo.png',
    'Aston Villa': 'assets/images/logos/epl/astonLogo.png',
    'Brighton': 'assets/images/logos/epl/brightonLogo.png',
    'Chelsea': 'assets/images/logos/epl/chelseaLogo.png',
    'Crystal Palace': 'assets/images/logos/epl/crystalpLogo.png',
    'Liverpool': 'assets/images/logos/epl/liverpoolLogo.png',
    'Manchester City': 'assets/images/logos/epl/mcityLogo.png',
    'Manchester United': 'assets/images/logos/epl/manuLogo.png',
    'Newcastle United': 'assets/images/logos/epl/newcastleLogo.png',
    'Nottingham Forest': 'assets/images/logos/epl/forestLogo.png',
    'Tottenham Hotspur': 'assets/images/logos/epl/tottenhamLogo.png',
    'West Ham United': 'assets/images/logos/epl/westHamLogo.png',

    // La Liga
    'Real Madrid': 'assets/images/logos/laLiga/rmaLogo.png',
    'Barcelona': 'assets/images/logos/laLiga/barcaLogo.png',
    'Atletico Madrid': 'assets/images/logos/laLiga/atmLogo.png',
    'Athletic Bilbao': 'assets/images/logos/laLiga/bilbaoLogo.png',
    'Real Betis': 'assets/images/logos/laLiga/betisLogo.png',
    'Sevilla': 'assets/images/logos/laLiga/sevillaLogo.png',
    'Villarreal': 'assets/images/logos/laLiga/villarrealLogo.png',

    // Bundesliga
    'Bayern Munich': 'assets/images/logos/bundesliga/bayernLogo.png',
    'Borussia Dortmund': 'assets/images/logos/bundesliga/bvbLogo.png',
    'Bayer Leverkusen': 'assets/images/logos/bundesliga/leverkusenLogo.png',
    'Eintracht Frankfurt': 'assets/images/logos/bundesliga/frankfurtLogo.png',
    'RB Leipzig': 'assets/images/logos/bundesliga/leipzigLogo.png',
    'VfL Wolfsburg': 'assets/images/logos/bundesliga/wolfsburgLogo.png',

    // Serie A
    'AC Milan': 'assets/images/logos/serieA/milanLogo.png',
    'Inter Milan': 'assets/images/logos/serieA/interLogo.png',
    'Juventus': 'assets/images/logos/serieA/juveLogo.png',
    'Napoli': 'assets/images/logos/serieA/napoliLogo.png',
    'Atalanta': 'assets/images/logos/serieA/atalantaLogo.png',
    'Roma': 'assets/images/logos/serieA/romaLogo.png',
    'Lazio': 'assets/images/logos/serieA/lazioLogo.png',
    'Fiorentina': 'assets/images/logos/serieA/fiorentinaLogo.png',

    // Ligue 1
    'PSG': 'assets/images/logos/league1/psgLogo.png',
    'Lyon': 'assets/images/logos/league1/lyonLogo.png',
    'Lille': 'assets/images/logos/league1/lilleLogo.png',
    'Marseille': 'assets/images/logos/league1/marsilyaLogo.png',
    'Monaco': 'assets/images/logos/league1/monacoLogo.png',

    // Trendyol Süper Lig
    'Galatasaray': 'assets/images/logos/superLig/gsLogo.png',
    'Fenerbahce': 'assets/images/logos/superLig/fbLogo.png',
    'Besiktas': 'assets/images/logos/superLig/bjkLogo.png',
    'Trabzonspor': 'assets/images/logos/superLig/tsLogo.png',
    'Başakşehir': 'assets/images/logos/superLig/basakLogo.png',
  };

  /// Country → ISO-3166 alpha-2 code for flagcdn.com. UK home nations use the
  /// special `gb-eng/sct/wls/nir` codes flagcdn supports. Countries without a
  /// mapping fall back to their text label.
  static const Map<String, String> _countryIso2 = {
    'France': 'fr',
    'Spain': 'es',
    'Argentina': 'ar',
    'England': 'gb-eng',
    'Portugal': 'pt',
    'Brazil': 'br',
    'Netherlands': 'nl',
    'Morocco': 'ma',
    'Belgium': 'be',
    'Germany': 'de',
    'Croatia': 'hr',
    'Italy': 'it',
    'Colombia': 'co',
    'Senegal': 'sn',
    'Mexico': 'mx',
    'USA': 'us',
    'Uruguay': 'uy',
    'Japan': 'jp',
    'Switzerland': 'ch',
    'Denmark': 'dk',
    'Iran': 'ir',
    'Turkiye': 'tr',
    'Ecuador': 'ec',
    'Austria': 'at',
    'South Korea': 'kr',
    'Nigeria': 'ng',
    'Australia': 'au',
    'Algeria': 'dz',
    'Egypt': 'eg',
    'Canada': 'ca',
    'Norway': 'no',
    'Ukraine': 'ua',
    'Panama': 'pa',
    'Ivory Coast': 'ci',
    'Poland': 'pl',
    'Russia': 'ru',
    'Wales': 'gb-wls',
    'Sweden': 'se',
    'Serbia': 'rs',
    'Paraguay': 'py',
    'Czechia': 'cz',
    'Hungary': 'hu',
    'Scotland': 'gb-sct',
    'Tunisia': 'tn',
    'Cameroon': 'cm',
    'DR Congo': 'cd',
    'Greece': 'gr',
    'Slovakia': 'sk',
    'Venezuela': 've',
    'Uzbekistan': 'uz',
    'Costa Rica': 'cr',
    'Mali': 'ml',
    'Peru': 'pe',
    'Chile': 'cl',
    'Qatar': 'qa',
    'Romania': 'ro',
    'Iraq': 'iq',
    'Slovenia': 'si',
    'Ireland': 'ie',
    'South Africa': 'za',
    'Saudi Arabia': 'sa',
    'Burkina Faso': 'bf',
    'Jordan': 'jo',
    'Albania': 'al',
    'Bosnia': 'ba',
    'Honduras': 'hn',
    'North Macedonia': 'mk',
    'UAE': 'ae',
    'Cape Verde': 'cv',
    'N. Ireland': 'gb-nir',
    'Jamaica': 'jm',
    'Georgia': 'ge',
    'Finland': 'fi',
    'Ghana': 'gh',
    'Iceland': 'is',
  };
}
