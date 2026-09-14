import 'package:bronchtracker/data/demo_data.dart';
import 'package:bronchtracker/insights/insights.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('peak flow zones', () {
    test('green at 80% and above', () {
      expect(peakFlowZone(208, 260), PefZone.green);
      expect(peakFlowZone(260, 260), PefZone.green);
    });
    test('yellow between 50% and 80%', () {
      expect(peakFlowZone(207, 260), PefZone.yellow);
      expect(peakFlowZone(130, 260), PefZone.yellow);
    });
    test('red below 50%', () {
      expect(peakFlowZone(129, 260), PefZone.red);
    });
    test('unknown without personal best', () {
      expect(peakFlowZone(200, null), PefZone.unknown);
      expect(peakFlowZone(null, 260), PefZone.unknown);
    });
  });

  group('json roundtrip', () {
    test('demo family survives serialize', () {
      final now = DateTime(2026, 9, 14, 15);
      final data = buildDemoData(now);
      final copy = AppData.fromJson(data.toJson());
      expect(copy.children.length, 2);
      expect(copy.children.first.name, 'Alex');
      expect(copy.episodes.length, data.episodes.length);
      expect(copy.checkIns.length, data.checkIns.length);
      expect(copy.medications.where((m) => m.kind == MedKind.controller), isNotEmpty);
    });

    test('merge keeps newer record', () {
      final a = AppData(
        children: [
          ChildProfile(
            id: 'c1',
            name: 'Old',
            updatedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final b = AppData(
        children: [
          ChildProfile(
            id: 'c1',
            name: 'New',
            updatedAt: DateTime(2026, 2, 1),
          ),
        ],
      );
      expect(AppData.merge(a, b).children.single.name, 'New');
    });
  });

  group('stats and suggestions', () {
    late AppData demo;
    late ChildProfile alex;
    final now = DateTime(2026, 9, 14, 18);

    setUp(() {
      demo = buildDemoData(now);
      alex = demo.children.first;
    });

    test('month window counts alex episodes and colds trigger', () {
      final stats = computeStats(
        child: alex,
        episodes: demo.episodes,
        checkIns: demo.checkIns,
        medications: demo.medications,
        period: StatsPeriod.month,
        now: now,
      );
      expect(stats.episodeCount, greaterThanOrEqualTo(3));
      expect(stats.triggerCounts[TriggerTag.colds]! +
          stats.triggerCounts[TriggerTag.exercise]!, greaterThan(0));
      expect(stats.avgSeverity, greaterThan(1));
      expect(stats.hasController, isTrue);
      expect(stats.nighttimeRate, greaterThan(0));
    });

    test('improvement cards stay educational and include colds / night', () {
      final stats = computeStats(
        child: alex,
        episodes: demo.episodes,
        checkIns: demo.checkIns,
        medications: demo.medications,
        period: StatsPeriod.year,
        now: now,
      );
      final cards = proposeImprovements(
        child: alex,
        stats: stats,
        episodes: demo.episodes,
        checkIns: demo.checkIns,
      );
      expect(cards, isNotEmpty);
      expect(cards.any((c) => c.id == 'colds_cluster' || c.id == 'night_symptoms' || c.id == 'er_visits'), isTrue);
      for (final c in cards) {
        expect(c.body.toLowerCase(), isNot(contains('you have asthma because')));
        expect(c.body.toLowerCase(), isNot(contains('take 2 puffs now')));
      }
    });

    test('visit summary mentions not a medical record', () {
      final stats = computeStats(
        child: alex,
        episodes: demo.episodes,
        checkIns: demo.checkIns,
        medications: demo.medications,
        period: StatsPeriod.month,
        now: now,
      );
      final text = visitSummaryText(
        child: alex,
        stats: stats,
        episodes: demo.episodes,
      );
      expect(text, contains('not a medical record'));
      expect(text, contains('Alex'));
      expect(text.toLowerCase(), contains('emergency'));
    });

    test('season range starts in September for fall', () {
      final range = rangeForPeriod(StatsPeriod.season, now);
      expect(range.start, DateTime(2026, 9, 1));
      expect(seasonName(now), 'Fall');
    });
  });
}
