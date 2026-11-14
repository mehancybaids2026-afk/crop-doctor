import 'package:flutter/material.dart';

import 'data_loader.dart';
import 'crop_rules.dart';

void main() => runApp(const CropDoctorApp());

class CropDoctorApp extends StatelessWidget {
  const CropDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const FormScreen(),
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final villages = [
    'Kundrathur',
    'Mangadu',
    'Poonamallee',
    'Pallavaram',
    'Sriperumbudur',
  ];
  final soils = ['Red', 'Black', 'Sandy', 'Clay'];
  final crops = ['Rice', 'Groundnut', 'Ragi', 'Black gram', 'Sugarcane'];
  final waters = ['Low', 'Medium', 'High'];
  final seasons = ['Kharif', 'Rabi', 'Summer'];

  String village = 'Kundrathur';
  String soil = 'Red';
  String crop = 'Rice';
  String water = 'Medium';
  String season = 'Kharif';

  Widget pick(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌾 Crop Doctor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tell us about your field',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          pick(
            'Village',
            village,
            villages,
            (v) => setState(() => village = v),
          ),
          pick('Soil type', soil, soils, (v) => setState(() => soil = v)),
          pick('Current crop', crop, crops, (v) => setState(() => crop = v)),
          pick(
            'Available water',
            water,
            waters,
            (v) => setState(() => water = v),
          ),
          pick(
            'Farming season',
            season,
            seasons,
            (v) => setState(() => season = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      village: village,
                      soil: soil,
                      crop: crop,
                      water: water,
                      season: season,
                    ),
                  ),
                );
              },
              child: const Text(
                'Check my field',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color scoreColor(double s) =>
    s >= 70 ? Colors.green : (s >= 45 ? Colors.orange : Colors.red);

class ResultScreen extends StatelessWidget {
  final String village, soil, crop, water, season;
  const ResultScreen({
    super.key,
    required this.village,
    required this.soil,
    required this.crop,
    required this.water,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Result: $village')),
      body: FutureBuilder<List<YearData>>(
        future: loadVillage(village),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Data error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = analyse(snap.data!);
          final scores = scoreCrops(
            rain: info.recentRain,
            temp: info.recentTemp,
            soilWet: info.recentWet,
            soil: soil,
            water: water,
            season: season,
          );
          final current = scores.firstWhere((c) => c.name == crop);
          final ranked = [...scores]
            ..sort((a, b) => b.score.compareTo(a.score));
          final top3 = ranked.take(3).toList();

          final hotterText = info.hotterBy > 0.1
              ? 'Yes. The last 5 years were ${info.hotterBy.toStringAsFixed(2)}°C hotter than the 5 years before.'
              : 'No clear warming. The change is ${info.hotterBy.toStringAsFixed(2)}°C.';
          final rainText = info.recentRain >= current.needMm
              ? 'Yes. Average rain is ${info.recentRain.round()} mm and $crop needs about ${current.needMm.round()} mm.'
              : 'No. Average rain is ${info.recentRain.round()} mm but $crop needs about ${current.needMm.round()} mm.';
          final waterText = (water == 'Low' || info.recentWet < 0.4)
              ? 'Yes, water availability is low. Soil wetness is ${info.recentWet.toStringAsFixed(2)} (0 = dry, 1 = soaked).'
              : 'No, water looks acceptable. Soil wetness is ${info.recentWet.toStringAsFixed(2)}.';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Data: NASA POWER, last 5 years average',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                color: scoreColor(current.score).withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current crop: $crop',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Score: ${current.score.round()} / 100',
                        style: TextStyle(
                          fontSize: 28,
                          color: scoreColor(current.score),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Why: ${current.reason}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Best crops for next season',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (final c in top3)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scoreColor(c.score),
                      child: Text(
                        '${c.score.round()}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.reason),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Your 5 answers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('1. Is the region getting hotter?'),
                subtitle: Text(hotterText),
              ),
              ListTile(
                title: const Text('2. Is rainfall enough?'),
                subtitle: Text(rainText),
              ),
              ListTile(
                title: const Text('3. Is water availability low?'),
                subtitle: Text(waterText),
              ),
              ListTile(
                title: const Text('4. Is your current crop suitable?'),
                subtitle: Text(
                  current.score >= 70
                      ? 'Yes, it is a good match.'
                      : (current.score >= 45
                            ? 'Partly. It is risky.'
                            : 'No. Consider changing it.'),
                ),
              ),
              ListTile(
                title: const Text('5. Which crops suit next season?'),
                subtitle: Text(top3.map((c) => c.name).join(', ')),
              ),
              const SizedBox(height: 8),
              Text(
                'Worst years in the last 20 years: driest ${info.driest.year} '
                '(${info.driest.rain.round()} mm), wettest ${info.wettest.year} '
                '(${info.wettest.rain.round()} mm), hottest ${info.hottest.year}.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: scoring rules are simplified and can be refined with agronomists.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          );
        },
      ),
    );
  }
}
