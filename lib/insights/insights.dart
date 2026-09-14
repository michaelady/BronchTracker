import 'package:bronchtracker/models/models.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class DateRange {
  const DateRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);
}

DateRange rangeForPeriod(StatsPeriod period, DateTime now) {
  final end = now;
  switch (period) {
    case StatsPeriod.week:
      return DateRange(start: now.subtract(const Duration(days: 7)), end: end);
    case StatsPeriod.month:
      return DateRange(start: now.subtract(const Duration(days: 30)), end: end);
    case StatsPeriod.season:
      return DateRange(start: seasonStart(now), end: end);
    case StatsPeriod.year:
      return DateRange(start: now.subtract(const Duration(days: 365)), end: end);
  }
}

DateTime seasonStart(DateTime now) {
  final m = now.month;
  final year = now.year;
  if (m == 12 || m <= 2) {
    // meteorological winter: Dec–Feb
    final startYear = m == 12 ? year : year - 1;
    return DateTime(startYear, 12, 1);
  }
  if (m <= 5) return DateTime(year, 3, 1); // spring
  if (m <= 8) return DateTime(year, 6, 1); // summer
  return DateTime(year, 9, 1); // fall
}

String seasonName(DateTime now) {
  final m = now.month;
  if (m == 12 || m <= 2) return 'Winter';
  if (m <= 5) return 'Spring';
  if (m <= 8) return 'Summer';
  return 'Fall';
}

class ChildStats {
  ChildStats({
    required this.childId,
    required this.period,
    required this.range,
    required this.episodeCount,
    required this.episodesPerWeek,
    required this.avgSeverity,
    required this.nighttimeRate,
    required this.erRate,
    required this.steroidRate,
    required this.triggerCounts,
    required this.avgDaysBetween,
    required this.trend,
    required this.checkInCount,
    required this.daysInRange,
    required this.avgRescuePuffs,
    required this.nightWakingCheckIns,
    required this.yellowZoneDays,
    required this.redZoneDays,
    required this.weeklyCounts,
    required this.previousEpisodeCount,
    required this.hasController,
    required this.hasRescue,
  });

  final String childId;
  final StatsPeriod period;
  final DateRange range;
  final int episodeCount;
  final double episodesPerWeek;
  final double avgSeverity;
  final double nighttimeRate;
  final double erRate;
  final double steroidRate;
  final Map<TriggerTag, int> triggerCounts;
  final double? avgDaysBetween;
  final Trend trend;
  final int checkInCount;
  final int daysInRange;
  final double avgRescuePuffs;
  final int nightWakingCheckIns;
  final int yellowZoneDays;
  final int redZoneDays;
  final List<int> weeklyCounts;
  final int previousEpisodeCount;
  final bool hasController;
  final bool hasRescue;

  List<MapEntry<TriggerTag, int>> get topTriggers {
    final list = triggerCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

ChildStats computeStats({
  required ChildProfile child,
  required List<Episode> episodes,
  required List<CheckIn> checkIns,
  required List<Medication> medications,
  required StatsPeriod period,
  required DateTime now,
}) {
  final range = rangeForPeriod(period, now);
  final inRange = episodes
      .where((e) => e.childId == child.id && range.contains(e.startedAt))
      .toList()
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final checks = checkIns
      .where((c) => c.childId == child.id && range.contains(c.date))
      .toList();
  final days = now.difference(range.start).inDays.clamp(1, 400);
  final weeks = days / 7.0;

  final duration = range.end.difference(range.start);
  final prevRange = DateRange(
    start: range.start.subtract(duration),
    end: range.start,
  );
  final prev = episodes
      .where((e) => e.childId == child.id && prevRange.contains(e.startedAt))
      .length;

  final triggerCounts = {for (final t in TriggerTag.values) t: 0};
  var night = 0;
  var er = 0;
  var steroid = 0;
  var sev = 0;
  for (final e in inRange) {
    sev += e.severity;
    if (e.nighttime) night++;
    if (e.erOrUrgentCare) er++;
    if (e.steroidBurst) steroid++;
    for (final t in e.triggers) {
      triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
    }
  }

  double? avgGap;
  if (inRange.length >= 2) {
    var sum = 0.0;
    for (var i = 1; i < inRange.length; i++) {
      sum += inRange[i].startedAt
          .difference(inRange[i - 1].startedAt)
          .inHours
          .abs() /
          24.0;
    }
    avgGap = sum / (inRange.length - 1);
  }

  Trend trend;
  if (inRange.isEmpty && prev == 0) {
    trend = Trend.unknown;
  } else if (inRange.length + 2 <= prev) {
    trend = Trend.improving;
  } else if (inRange.length >= prev + 2) {
    trend = Trend.worsening;
  } else if (inRange.isNotEmpty && prev > 0) {
    final prevEps = episodes.where(
      (e) => e.childId == child.id && prevRange.contains(e.startedAt),
    );
    final prevSev = prevEps.isEmpty
        ? 0.0
        : prevEps.map((e) => e.severity).average;
    final curSev = inRange.map((e) => e.severity).average;
    if (curSev + 0.4 < prevSev) {
      trend = Trend.improving;
    } else if (curSev > prevSev + 0.4) {
      trend = Trend.worsening;
    } else {
      trend = Trend.stable;
    }
  } else {
    trend = Trend.stable;
  }

  final weekly = <int>[];
  final weekCount = (days / 7).ceil().clamp(1, 12);
  for (var w = weekCount - 1; w >= 0; w--) {
    final ws = now.subtract(Duration(days: (w + 1) * 7));
    final we = now.subtract(Duration(days: w * 7));
    weekly.add(
      inRange
          .where((e) => e.startedAt.isAfter(ws) && !e.startedAt.isAfter(we))
          .length,
    );
  }

  var yellow = 0;
  var red = 0;
  var nightWake = 0;
  var puffs = 0;
  for (final c in checks) {
    if (c.nightWaking) nightWake++;
    puffs += c.rescuePuffs;
    final z = peakFlowZone(c.peakFlow, child.peakFlowPersonalBest);
    if (z == PefZone.yellow) yellow++;
    if (z == PefZone.red) red++;
  }

  final childMeds = medications.where((m) => m.childId == child.id);
  return ChildStats(
    childId: child.id,
    period: period,
    range: range,
    episodeCount: inRange.length,
    episodesPerWeek: weeks == 0 ? 0 : inRange.length / weeks,
    avgSeverity: inRange.isEmpty ? 0 : sev / inRange.length,
    nighttimeRate: inRange.isEmpty ? 0 : night / inRange.length,
    erRate: inRange.isEmpty ? 0 : er / inRange.length,
    steroidRate: inRange.isEmpty ? 0 : steroid / inRange.length,
    triggerCounts: triggerCounts,
    avgDaysBetween: avgGap,
    trend: trend,
    checkInCount: checks.length,
    daysInRange: days,
    avgRescuePuffs: checks.isEmpty ? 0 : puffs / checks.length,
    nightWakingCheckIns: nightWake,
    yellowZoneDays: yellow,
    redZoneDays: red,
    weeklyCounts: weekly,
    previousEpisodeCount: prev,
    hasController: childMeds.any((m) => m.kind == MedKind.controller),
    hasRescue: childMeds.any((m) => m.kind == MedKind.rescue),
  );
}

class Suggestion {
  const Suggestion({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
  });

  final String id;
  final String title;
  final String body;
  final int priority;
}

List<Suggestion> proposeImprovements({
  required ChildProfile child,
  required ChildStats stats,
  required List<Episode> episodes,
  required List<CheckIn> checkIns,
}) {
  final out = <Suggestion>[];
  final tops = stats.topTriggers;
  final top = tops.isEmpty ? null : tops.first;

  if (top != null && top.key == TriggerTag.colds && top.value >= 2) {
    out.add(
      const Suggestion(
        id: 'colds_cluster',
        title: 'Episodes cluster after colds',
        body:
            'Viral illness shows up often with logged episodes. This is a common pattern to discuss with your clinician — including whether controller timing around cold season needs a review. BronchTracker cannot diagnose or change medicines.',
        priority: 10,
      ),
    );
  }
  if (stats.nighttimeRate >= 0.35 || stats.nightWakingCheckIns >= 3) {
    out.add(
      const Suggestion(
        id: 'night_symptoms',
        title: 'Night symptoms are showing up',
        body:
            'Night waking or nighttime episodes are more frequent in this period. Review the yellow-zone notes in your action plan and bring this log to the next visit. This is not an emergency assessment.',
        priority: 9,
      ),
    );
  }
  if (stats.erRate > 0) {
    out.add(
      const Suggestion(
        id: 'er_visits',
        title: 'Urgent care or ER was logged',
        body:
            'Share dates, severity, and triggers from this log at the follow-up visit. For severe distress now (trouble speaking, blue lips, or you are worried), call emergency services — this app is not emergency care.',
        priority: 12,
      ),
    );
  }
  if (stats.trend == Trend.worsening) {
    out.add(
      const Suggestion(
        id: 'worsening',
        title: 'Frequency looks higher recently',
        body:
            'Compared with the previous stretch, more episodes were logged. Use this as a prompt to review the written action plan with your clinician. Trends here are educational, not a diagnosis.',
        priority: 8,
      ),
    );
  }
  if (stats.trend == Trend.improving && stats.episodeCount > 0) {
    out.add(
      const Suggestion(
        id: 'improving',
        title: 'Fewer episodes lately',
        body:
            'Logging still helps: a calmer stretch is useful context for your care team. Keep daily check-ins going so the pattern stays visible.',
        priority: 3,
      ),
    );
  }
  if (stats.avgRescuePuffs >= 3) {
    out.add(
      const Suggestion(
        id: 'rescue_elevated',
        title: 'Rescue puffs are elevated',
        body:
            'Average rescue-inhaler use on check-in days is on the high side. Ask your clinician when yellow-zone steps should start. BronchTracker does not prescribe doses.',
        priority: 8,
      ),
    );
  }
  if (stats.redZoneDays > 0) {
    out.add(
      const Suggestion(
        id: 'pef_red',
        title: 'Peak flow entered the red zone',
        body:
            'Follow the red-zone instructions you stored in the action plan and seek urgent care if breathing is severely labored. Peak-flow zones here are a home diary aid, not a medical device reading.',
        priority: 11,
      ),
    );
  } else if (stats.yellowZoneDays >= 2) {
    out.add(
      const Suggestion(
        id: 'pef_yellow',
        title: 'Several yellow-zone peak flows',
        body:
            'Review your yellow-zone action-plan notes (extra monitoring, contacting the clinic, etc.). Personal-best percentages are a tracking helper, not a diagnosis.',
        priority: 7,
      ),
    );
  }
  if (top != null && top.key == TriggerTag.exercise && top.value >= 2) {
    out.add(
      const Suggestion(
        id: 'exercise',
        title: 'Exercise-tagged episodes',
        body:
            'A clinician can advise on warm-up and any pre-exercise rescue plan. We cannot tell you what to take or when.',
        priority: 6,
      ),
    );
  }
  if (top != null && top.key == TriggerTag.pollen && top.value >= 2) {
    out.add(
      const Suggestion(
        id: 'pollen',
        title: 'Pollen shows up with episodes',
        body:
            'Outdoor allergens are a frequent discussion at visits. Consider noting outdoor time alongside check-ins so your clinician can see the pattern.',
        priority: 5,
      ),
    );
  }
  if ((stats.triggerCounts[TriggerTag.smoke] ?? 0) +
          (stats.triggerCounts[TriggerTag.dust] ?? 0) >=
      2) {
    out.add(
      const Suggestion(
        id: 'smoke_dust',
        title: 'Smoke or dust tags are common',
        body:
            'Reducing exposure (smoke-free spaces, dust control) is a typical environmental topic — confirm ideas with your care team rather than treating this as medical advice.',
        priority: 5,
      ),
    );
  }
  if (!stats.hasController &&
      child.diagnoses.contains(DiagnosisTag.asthma) &&
      stats.episodeCount >= 2) {
    out.add(
      const Suggestion(
        id: 'no_controller',
        title: 'No controller medicine is listed',
        body:
            'If a daily controller was prescribed, add it under Meds so the log matches real life. If none was prescribed, ask at the next visit whether that is still the plan. This app does not recommend starting medicines.',
        priority: 6,
      ),
    );
  }
  final checkInCoverage = stats.checkInCount / stats.daysInRange;
  if (checkInCoverage < 0.4 && stats.daysInRange >= 7) {
    out.add(
      const Suggestion(
        id: 'sparse_checkins',
        title: 'Daily check-ins are sparse',
        body:
            'Symptom-free days matter as much as hard days. A steadier diary makes frequency and trigger patterns more trustworthy.',
        priority: 4,
      ),
    );
  }
  if (stats.steroidRate >= 0.25 && stats.episodeCount >= 2) {
    out.add(
      const Suggestion(
        id: 'steroid_bursts',
        title: 'Steroid bursts were used more than once',
        body:
            'Track dates and bring them to clinic visits. Only a clinician should decide if the action plan or controllers need a change.',
        priority: 7,
      ),
    );
  }
  final month = DateTime.now().month;
  final coldSeason = month >= 9 || month <= 3;
  if (coldSeason &&
      (top?.key == TriggerTag.coldAir || top?.key == TriggerTag.colds)) {
    out.add(
      const Suggestion(
        id: 'seasonal_cold',
        title: 'Cooler-month pattern',
        body:
            'Colds and cold air often cluster in fall and winter. A seasonal review of the action plan (green vs yellow steps) is a reasonable question for your clinician — not a treatment change from this app.',
        priority: 5,
      ),
    );
  }
  if (stats.episodeCount == 0 && stats.checkInCount > 0) {
    out.add(
      const Suggestion(
        id: 'quiet_period',
        title: 'A quieter stretch',
        body:
            'No episodes in this window. Keep logging check-ins and peak flow so you can show a full picture at the next visit.',
        priority: 2,
      ),
    );
  }

  out.sort((a, b) => b.priority.compareTo(a.priority));
  final seen = <String>{};
  return [
    for (final s in out)
      if (seen.add(s.id)) s,
  ].take(6).toList();
}

String visitSummaryText({
  required ChildProfile child,
  required ChildStats stats,
  required List<Episode> episodes,
}) {
  final df = DateFormat.yMMMd();
  final buf = StringBuffer()
    ..writeln('BronchTracker visit summary for ${child.name}')
    ..writeln('(Home diary — not a medical record or diagnosis.)')
    ..writeln(
      'Period: ${df.format(stats.range.start)} – ${df.format(stats.range.end)}',
    )
    ..writeln('Logged diagnosis tags: ${child.diagnosisSummary}')
    ..writeln('Episodes: ${stats.episodeCount}  ·  ${stats.episodesPerWeek.toStringAsFixed(1)} / week')
    ..writeln(
      'Average severity (1–5): ${stats.avgSeverity == 0 ? "—" : stats.avgSeverity.toStringAsFixed(1)}',
    )
    ..writeln(
      'Nighttime episodes: ${(stats.nighttimeRate * 100).round()}%  ·  ER/urgent: ${(stats.erRate * 100).round()}%',
    );
  if (stats.avgDaysBetween != null) {
    buf.writeln(
      'Average days between episodes: ${stats.avgDaysBetween!.toStringAsFixed(1)}',
    );
  }
  final tops = stats.topTriggers.take(5);
  if (tops.isNotEmpty) {
    buf.writeln(
      'Top triggers: ${tops.map((e) => "${e.key.label} (${e.value})").join(", ")}',
    );
  }
  buf
    ..writeln(
      'Check-ins: ${stats.checkInCount}  ·  avg rescue puffs: ${stats.avgRescuePuffs.toStringAsFixed(1)}',
    )
    ..writeln(
      'Peak-flow yellow days: ${stats.yellowZoneDays}  ·  red days: ${stats.redZoneDays}',
    )
    ..writeln('Trend (educational): ${stats.trend.name}');
  final recent = episodes
      .where((e) => e.childId == child.id)
      .toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  if (recent.isNotEmpty) {
    buf.writeln('Recent episodes:');
    for (final e in recent.take(8)) {
      buf.writeln(
        '  - ${df.format(e.startedAt)} ${e.type.shortLabel} sev ${e.severity}'
        '${e.nighttime ? " night" : ""}'
        '${e.erOrUrgentCare ? " ER/UC" : ""}'
        ' triggers: ${e.triggers.map((t) => t.label).join("/")}',
      );
    }
  }
  buf.writeln(
    'If breathing is severely distressed, call emergency services. This summary does not replace clinical judgment.',
  );
  return buf.toString();
}
