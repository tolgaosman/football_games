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
        final iso = _countryIso2[factor.value];
        if (iso == null) return FactorArt.none;
        return FactorArt(networkUrl: 'https://flagcdn.com/w160/$iso.png');

      case FactorType.playedLeague:
        final url = _leagueBadgeUrl[factor.value];
        return url == null ? FactorArt.none : FactorArt(networkUrl: url);

      case FactorType.wonLeague:
        final url = _leagueBadgeUrl[factor.value];
        return url == null
            ? FactorArt.none
            : FactorArt(networkUrl: url, isWonLeague: true);

      case FactorType.team:
        final url = _teamBadgeUrl[factor.value];
        return url == null ? FactorArt.none : FactorArt(networkUrl: url);

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

  /// League badge URLs (TheSportsDB CDN), keyed by canonical league name.
  static const Map<String, String> _leagueBadgeUrl = {
    'Premier League':
        'https://r2.thesportsdb.com/images/media/league/badge/gasy9d1737743125.png',
    'La Liga':
        'https://r2.thesportsdb.com/images/media/league/badge/ja4it51687628717.png',
    'Serie A':
        'https://r2.thesportsdb.com/images/media/league/badge/67q3q21679951383.png',
    'Bundesliga':
        'https://r2.thesportsdb.com/images/media/league/badge/teqh1b1679952008.png',
    'Ligue 1':
        'https://r2.thesportsdb.com/images/media/league/badge/9f7z9d1742983155.png',
    'Trendyol Süper Lig':
        'https://r2.thesportsdb.com/images/media/league/badge/ifm3zc1779990699.png',
  };

  /// Club badge URLs (TheSportsDB CDN), keyed by canonical club name.
  static const Map<String, String> _teamBadgeUrl = {
    'Arsenal':
        'https://r2.thesportsdb.com/images/media/team/badge/uyhbfe1612467038.png',
    'Manchester City':
        'https://r2.thesportsdb.com/images/media/team/badge/vwpvry1467462651.png',
    'Liverpool':
        'https://r2.thesportsdb.com/images/media/team/badge/kfaher1737969724.png',
    'Chelsea':
        'https://r2.thesportsdb.com/images/media/team/badge/yvwvtu1448813215.png',
    'Manchester United':
        'https://r2.thesportsdb.com/images/media/team/badge/xzqdr11517660252.png',
    'Real Madrid':
        'https://r2.thesportsdb.com/images/media/team/badge/vwvwrw1473502969.png',
    'Barcelona':
        'https://r2.thesportsdb.com/images/media/team/badge/wq9sir1639406443.png',
    'Atletico Madrid':
        'https://r2.thesportsdb.com/images/media/team/badge/0ulh3q1719984315.png',
    'Bayern Munich':
        'https://r2.thesportsdb.com/images/media/team/badge/01ogkh1716960412.png',
    'Borussia Dortmund':
        'https://r2.thesportsdb.com/images/media/team/badge/tqo8ge1716960353.png',
    'Juventus':
        'https://r2.thesportsdb.com/images/media/team/badge/uxf0gr1742983727.png',
    'AC Milan':
        'https://r2.thesportsdb.com/images/media/team/badge/wvspur1448806617.png',
    'Inter Milan':
        'https://r2.thesportsdb.com/images/media/team/badge/ryhu6d1617113103.png',
    'Napoli':
        'https://r2.thesportsdb.com/images/media/team/badge/l8qyxv1742982541.png',
    'PSG':
        'https://r2.thesportsdb.com/images/media/team/badge/rwqrrq1473504808.png',
    'Marseille':
        'https://r2.thesportsdb.com/images/media/team/badge/c6bazh1779212287.png',
    'Lyon':
        'https://r2.thesportsdb.com/images/media/team/badge/blk9771656932845.png',
    'Galatasaray':
        'https://r2.thesportsdb.com/images/media/team/badge/io7jk21767941298.png',
    'Fenerbahce':
        'https://r2.thesportsdb.com/images/media/team/badge/twxxvs1448199691.png',
    'Besiktas':
        'https://r2.thesportsdb.com/images/media/team/badge/svo05k1776827439.png',
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
