class CropInfo {
  final String name;
  final double needMm; // rainfall the crop needs per year
  final double maxTemp; // average temperature above which it suffers
  final List<String> soils;
  final List<String> seasons;
  final bool helpsSoil;
  const CropInfo(
    this.name,
    this.needMm,
    this.maxTemp,
    this.soils,
    this.seasons,
    this.helpsSoil,
  );
}

// Placeholder values. Person 2 will replace them with researched ones.
const List<CropInfo> cropTable = [
  CropInfo('Rice', 1200, 31, ['Clay', 'Black'], ['Kharif', 'Rabi'], false),
  CropInfo('Groundnut', 600, 32, ['Red', 'Sandy'], ['Kharif', 'Summer'], true),
  CropInfo('Ragi', 500, 34, ['Red', 'Sandy'], ['Kharif', 'Rabi'], false),
  CropInfo(
    'Black gram',
    450,
    33,
    ['Red', 'Black', 'Clay'],
    ['Kharif', 'Rabi'],
    true,
  ),
  CropInfo(
    'Sugarcane',
    1800,
    32,
    ['Black', 'Clay'],
    ['Kharif', 'Summer'],
    false,
  ),
];

class CropScore {
  final String name;
  final double score; // 0 to 100
  final double needMm;
  final String reason;
  CropScore(this.name, this.score, this.needMm, this.reason);
}

List<CropScore> scoreCrops({
  required double rain,
  required double temp,
  required double soilWet,
  required String soil,
  required String water,
  required String season,
}) {
  // Farmer's water can make up for missing rain
  final double helpFactor = water == 'High'
      ? 0.4
      : (water == 'Medium' ? 0.7 : 1.0);
  final List<CropScore> out = [];

  for (final c in cropTable) {
    double s = 100;
    final reasons = <String>[];

    if (rain < c.needMm) {
      final lost = (c.needMm - rain) / c.needMm * 80 * helpFactor;
      s -= lost;
      if (lost > 5) reasons.add('rain is below what it needs');
    }
    if (water == 'Low' && c.needMm >= 900) {
      s -= 15;
      reasons.add('needs lots of water but your water is low');
    }
    if (temp > c.maxTemp) {
      s -= (temp - c.maxTemp) * 8;
      reasons.add('too hot for it');
    }
    if (!c.soils.contains(soil)) {
      s -= 15;
      reasons.add('$soil soil is not ideal');
    }
    if (!c.seasons.contains(season)) {
      s -= 25;
      reasons.add('not usually grown in $season');
    }
    if (c.helpsSoil) s += 5;

    s = s.clamp(0, 100).toDouble();
    final reason = reasons.isEmpty
        ? 'Good match for your conditions'
        : reasons.join(', ');

    out.add(CropScore(c.name, s, c.needMm, reason));
  }

  out.sort((a, b) => b.score.compareTo(a.score));

  return out;
}
