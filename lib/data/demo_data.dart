import 'package:bronchtracker/models/models.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

AppData buildDemoData(DateTime now) {
  final alexId = 'demo-alex';
  final samId = 'demo-sam';

  final alex = ChildProfile(
    id: alexId,
    name: 'Alex',
    birthYear: now.year - 8,
    diagnoses: const [DiagnosisTag.asthma, DiagnosisTag.bronchitis],
    peakFlowPersonalBest: 260,
    greenPlan:
        'Usual controller every day. Play and school as normal. Rescue inhaler nearby for sports. Recheck peak flow if a cold starts.',
    yellowPlan:
        'Cough or wheeze, night waking, or peak flow 50–80% of personal best: extra rest, rescue as written by our clinician, note puffs, call clinic if not improving in a few hours.',
    redPlan:
        'Severe distress, peak flow under 50%, lips/nails blue, or cannot speak in sentences: rescue per our written plan and call emergency services. This app is not 911.',
    updatedAt: now,
  );

  final sam = ChildProfile(
    id: samId,
    name: 'Sam',
    birthYear: now.year - 5,
    diagnoses: const [DiagnosisTag.bronchitis],
    peakFlowPersonalBest: null,
    greenPlan: 'Baseline: easy breathing, overnight sleep through, usual energy.',
    yellowPlan:
        'Wet cough lasting into the night or extra work of breathing — contact the pediatric clinic the same day if it is new for Sam.',
    redPlan:
        'Ribs pulling in, cannot drink, or you are frightened: emergency services. BronchTracker is not emergency care.',
    updatedAt: now,
  );

  final meds = [
    Medication(
      id: 'demo-med-ics',
      childId: alexId,
      name: 'Inhaled corticosteroid (demo)',
      kind: MedKind.controller,
      dose: 'As prescribed — example only',
      schedule: 'Morning and evening',
      updatedAt: now,
    ),
    Medication(
      id: 'demo-med-rescue-a',
      childId: alexId,
      name: 'Albuterol / salbutamol (demo)',
      kind: MedKind.rescue,
      dose: 'As prescribed — example only',
      schedule: 'For symptoms / pre-exercise if advised',
      updatedAt: now,
    ),
    Medication(
      id: 'demo-med-rescue-s',
      childId: samId,
      name: 'Rescue inhaler (demo)',
      kind: MedKind.rescue,
      dose: 'As prescribed — example only',
      schedule: 'With wheeze, if prescribed',
      updatedAt: now,
    ),
  ];

  DateTime daysAgo(int d, {int hour = 18, int minute = 0}) =>
      DateTime(now.year, now.month, now.day, hour, minute).subtract(Duration(days: d));

  final episodes = <Episode>[
    Episode(
      id: 'demo-ep-1',
      childId: alexId,
      type: EpisodeType.bronchitisFlare,
      startedAt: daysAgo(4, hour: 22),
      durationMinutes: 90,
      severity: 4,
      nighttime: true,
      erOrUrgentCare: false,
      steroidBurst: true,
      notes: 'Followed a cold that started at school. Demo data.',
      triggers: const [TriggerTag.colds, TriggerTag.weatherChange],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-2',
      childId: alexId,
      type: EpisodeType.wheeze,
      startedAt: daysAgo(6, hour: 7),
      durationMinutes: 35,
      severity: 3,
      nighttime: false,
      notes: 'Morning wheeze after gym class the day before.',
      triggers: const [TriggerTag.exercise, TriggerTag.colds],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-3',
      childId: alexId,
      type: EpisodeType.asthmaAttack,
      startedAt: daysAgo(18, hour: 21),
      durationMinutes: 50,
      severity: 4,
      nighttime: true,
      erOrUrgentCare: false,
      notes: 'Cold air after soccer. Demo.',
      triggers: const [TriggerTag.coldAir, TriggerTag.exercise],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-4',
      childId: alexId,
      type: EpisodeType.coughBout,
      startedAt: daysAgo(27, hour: 23),
      durationMinutes: 40,
      severity: 2,
      nighttime: true,
      triggers: const [TriggerTag.colds],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-5',
      childId: alexId,
      type: EpisodeType.wheeze,
      startedAt: daysAgo(41, hour: 16),
      durationMinutes: 25,
      severity: 3,
      triggers: const [TriggerTag.pollen, TriggerTag.exercise],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-6',
      childId: alexId,
      type: EpisodeType.bronchitisFlare,
      startedAt: daysAgo(62, hour: 20),
      durationMinutes: 180,
      severity: 5,
      nighttime: true,
      erOrUrgentCare: true,
      steroidBurst: true,
      notes: 'Urgent care visit after a virus. Demo only.',
      triggers: const [TriggerTag.colds, TriggerTag.unknown],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-7',
      childId: alexId,
      type: EpisodeType.coughBout,
      startedAt: daysAgo(78, hour: 6),
      durationMinutes: 20,
      severity: 2,
      triggers: const [TriggerTag.dust],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-s1',
      childId: samId,
      type: EpisodeType.bronchitisFlare,
      startedAt: daysAgo(9, hour: 21),
      durationMinutes: 120,
      severity: 3,
      nighttime: true,
      notes: 'Post-viral cough. Demo.',
      triggers: const [TriggerTag.colds],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-s2',
      childId: samId,
      type: EpisodeType.wheeze,
      startedAt: daysAgo(33, hour: 19),
      durationMinutes: 30,
      severity: 2,
      triggers: const [TriggerTag.colds, TriggerTag.weatherChange],
      updatedAt: now,
    ),
    Episode(
      id: 'demo-ep-s3',
      childId: samId,
      type: EpisodeType.coughBout,
      startedAt: daysAgo(55, hour: 22),
      durationMinutes: 45,
      severity: 3,
      nighttime: true,
      triggers: const [TriggerTag.colds],
      updatedAt: now,
    ),
  ];

  final checkIns = <CheckIn>[];
  for (var d = 0; d < 16; d++) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
    final afterCold = d <= 6;
    checkIns.add(
      CheckIn(
        id: 'demo-ci-a-$d',
        childId: alexId,
        date: day.add(const Duration(hours: 19)),
        wheeze: afterCold && d % 2 == 0,
        cough: afterCold,
        shortnessOfBreath: d == 4 || d == 5,
        chestTightness: d == 4,
        nightWaking: d <= 5 && d != 2,
        rescuePuffs: afterCold ? (d <= 4 ? 4 : 2) : (d % 5 == 0 ? 1 : 0),
        peakFlow: afterCold
            ? (d <= 4 ? 150 + d * 8 : 210)
            : 230 + (d % 3) * 5,
        notes: d == 0 ? 'Demo check-in seeded for Tester.' : '',
        updatedAt: now,
      ),
    );
    if (d % 2 == 0 && d < 12) {
      checkIns.add(
        CheckIn(
          id: 'demo-ci-s-$d',
          childId: samId,
          date: day.add(const Duration(hours: 20)),
          cough: d <= 10,
          wheeze: d == 8 || d == 9,
          nightWaking: d == 8,
          rescuePuffs: d == 8 ? 2 : 0,
          notes: '',
          updatedAt: now,
        ),
      );
    }
  }

  return AppData(
    children: [alex, sam],
    episodes: episodes,
    checkIns: checkIns,
    medications: meds,
    settings: AppSettings(
      disclaimerAccepted: true,
      selectedChildId: alexId,
      reminderHour: 20,
      reminderMinute: 0,
      remindersEnabled: true,
      updatedAt: now,
    ),
  );
}
