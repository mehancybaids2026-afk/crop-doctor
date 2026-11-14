import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// One year of NASA weather
class YearData {
  final int year;
  final double rain; // total mm in the year
  final double temp; // average temperature in C
  final double soilWet; // soil wetness, 0 (dry) to 1 (soaked)
  YearData(this.year, this.rain, this.temp, this.soilWet);
}

// Reads one village file and returns a list of years
Future<List<YearData>> loadVillage(String village) async {
  final name = village.toLowerCase();
  final raw = await rootBundle.loadString('assets/data/$name.json');
  final p = jsonDecode(raw)['properties']['parameter'];
  final rainMap = p['PRECTOTCORR'] as Map<String, dynamic>;
  final tempMap = p['T2M'] as Map<String, dynamic>;
  final wetMap = p['GWETROOT'] as Map<String, dynamic>;

  final Map<int, double> rainSum = {};
  final Map<int, double> tempSum = {};
  final Map<int, double> wetSum = {};
  final Map<int, int> count = {};

  rainMap.forEach((key, value) {
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(4));
    if (month < 1 || month > 12) return; // 13 = yearly average, skip
    final r = (value as num).toDouble();
    final t = (tempMap[key] as num).toDouble();
    final w = (wetMap[key] as num).toDouble();
    if (r < -900 || t < -900 || w < -900) return; // -999 = missing
    rainSum[year] = (rainSum[year] ?? 0) + r * 30.4; // mm/day to mm/month
    tempSum[year] = (tempSum[year] ?? 0) + t;
    wetSum[year] = (wetSum[year] ?? 0) + w;
    count[year] = (count[year] ?? 0) + 1;
  });

  final List<YearData> out = [];
  rainSum.forEach((year, rain) {
    if (count[year] == 12) {
      out.add(YearData(year, rain, tempSum[year]! / 12, wetSum[year]! / 12));
    }
  });
  out.sort((a, b) => a.year.compareTo(b.year));
  return out;
}

// The "smart facts" about a village
class Insights {
  final double recentRain, recentTemp, recentWet; // average of last 5 years
  final double hotterBy; // last 5 years minus the 5 before, in C
  final YearData driest, wettest, hottest;
  Insights(
    this.recentRain,
    this.recentTemp,
    this.recentWet,
    this.hotterBy,
    this.driest,
    this.wettest,
    this.hottest,
  );
}

double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

Insights analyse(List<YearData> y) {
  final last5 = y.sublist(y.length - 5);
  final before5 = y.sublist(y.length - 10, y.length - 5);
  return Insights(
    _avg(last5.map((e) => e.rain).toList()),
    _avg(last5.map((e) => e.temp).toList()),
    _avg(last5.map((e) => e.soilWet).toList()),
    _avg(last5.map((e) => e.temp).toList()) -
        _avg(before5.map((e) => e.temp).toList()),
    y.reduce((a, b) => a.rain < b.rain ? a : b),
    y.reduce((a, b) => a.rain > b.rain ? a : b),
    y.reduce((a, b) => a.temp > b.temp ? a : b),
  );
}
