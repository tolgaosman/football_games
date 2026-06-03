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

  /// League logo asset paths (user-supplied), keyed by canonical league name.
  /// Files live in `assets/images/logos/`.
  static const Map<String, String> _leagueLogoAsset = {
    'Premier League': 'assets/images/logos/premierLeague.png',
    'La Liga': 'assets/images/logos/laLiga.png',
    'Serie A': 'assets/images/logos/serieA.png',
    'Bundesliga': 'assets/images/logos/bundesliga.png',
    'Ligue 1': 'assets/images/logos/ligue1.png',
    'Trendyol Süper Lig': 'assets/images/logos/superLig.png',
  };

  /// Club logo asset paths (user-supplied), keyed by canonical club name.
  /// Files live in `assets/images/logos/` using camelCase filenames.
  static const Map<String, String> _teamLogoAsset = {
    'Arsenal': 'assets/images/logos/arsenal.png',
    'Manchester City': 'assets/images/logos/manchesterCity.png',
    'Liverpool': 'assets/images/logos/liverpool.png',
    'Chelsea': 'assets/images/logos/chelsea.png',
    'Manchester United': 'assets/images/logos/manchesterUnited.png',
    'Real Madrid': 'assets/images/logos/realMadrid.png',
    'Barcelona': 'assets/images/logos/barcelona.png',
    'Atletico Madrid': 'assets/images/logos/atleticoMadrid.png',
    'Bayern Munich': 'assets/images/logos/bayernMunich.png',
    'Borussia Dortmund': 'assets/images/logos/borussiaDortmund.png',
    'Juventus': 'assets/images/logos/juventus.png',
    'AC Milan': 'assets/images/logos/acMilan.png',
    'Inter Milan': 'assets/images/logos/interMilan.png',
    'Napoli': 'assets/images/logos/napoli.png',
    'PSG': 'assets/images/logos/psg.png',
    'Marseille': 'assets/images/logos/marseille.png',
    'Lyon': 'assets/images/logos/lyon.png',
    'Galatasaray': 'assets/images/logos/galatasaray.png',
    'Fenerbahce': 'assets/images/logos/fenerbahce.png',
    'Besiktas': 'assets/images/logos/besiktas.png',
    'Tottenham Hotspur': 'assets/images/logos/tottenhamHotspur.png',
    'Newcastle United': 'assets/images/logos/newcastleUnited.png',
    'Aston Villa': 'assets/images/logos/astonVilla.png',
    'Everton': 'assets/images/logos/everton.png',
    'West Ham United': 'assets/images/logos/westHamUnited.png',
    'Sevilla': 'assets/images/logos/sevilla.png',
    'Valencia': 'assets/images/logos/valencia.png',
    'Bayer Leverkusen': 'assets/images/logos/bayerLeverkusen.png',
    'Schalke 04': 'assets/images/logos/schalke04.png',
    'Werder Bremen': 'assets/images/logos/werderBremen.png',
    'Roma': 'assets/images/logos/roma.png',
    'Lazio': 'assets/images/logos/lazio.png',
    'Fiorentina': 'assets/images/logos/fiorentina.png',
    'Atalanta': 'assets/images/logos/atalanta.png',
    'Lille': 'assets/images/logos/lille.png',
    'Trabzonspor': 'assets/images/logos/trabzonspor.png',
    'Başakşehir': 'assets/images/logos/basaksehir.png',
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
