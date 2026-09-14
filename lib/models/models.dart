import 'package:collection/collection.dart';

enum DiagnosisTag {
  asthma,
  bronchitis,
  other;

  String get label => switch (this) {
    DiagnosisTag.asthma => 'Asthma',
    DiagnosisTag.bronchitis => 'Bronchitis',
    DiagnosisTag.other => 'Other',
  };
}

enum EpisodeType {
  asthmaAttack,
  bronchitisFlare,
  wheeze,
  coughBout,
  other;

  String get label => switch (this) {
    EpisodeType.asthmaAttack => 'Asthma attack',
    EpisodeType.bronchitisFlare => 'Bronchitis flare',
    EpisodeType.wheeze => 'Wheeze',
    EpisodeType.coughBout => 'Cough bout',
    EpisodeType.other => 'Other',
  };

  String get shortLabel => switch (this) {
    EpisodeType.asthmaAttack => 'Asthma',
    EpisodeType.bronchitisFlare => 'Bronchitis',
    EpisodeType.wheeze => 'Wheeze',
    EpisodeType.coughBout => 'Cough',
    EpisodeType.other => 'Other',
  };
}

enum TriggerTag {
  colds,
  coldAir,
  pollen,
  exercise,
  smoke,
  dust,
  pets,
  weatherChange,
  unknown;

  String get label => switch (this) {
    TriggerTag.colds => 'Colds / virus',
    TriggerTag.coldAir => 'Cold air',
    TriggerTag.pollen => 'Pollen',
    TriggerTag.exercise => 'Exercise',
    TriggerTag.smoke => 'Smoke',
    TriggerTag.dust => 'Dust',
    TriggerTag.pets => 'Pets',
    TriggerTag.weatherChange => 'Weather change',
    TriggerTag.unknown => 'Unknown',
  };
}

enum MedKind {
  controller,
  rescue,
  other;

  String get label => switch (this) {
    MedKind.controller => 'Controller',
    MedKind.rescue => 'Rescue',
    MedKind.other => 'Other',
  };
}

enum PefZone {
  green,
  yellow,
  red,
  unknown;

  String get label => switch (this) {
    PefZone.green => 'Green',
    PefZone.yellow => 'Yellow',
    PefZone.red => 'Red',
    PefZone.unknown => 'No zone',
  };
}

enum StatsPeriod { week, month, season, year }

enum Trend { improving, stable, worsening, unknown }

PefZone peakFlowZone(int? peakFlow, int? personalBest) {
  if (peakFlow == null || personalBest == null || personalBest <= 0) {
    return PefZone.unknown;
  }
  final pct = peakFlow / personalBest;
  if (pct >= 0.80) return PefZone.green;
  if (pct >= 0.50) return PefZone.yellow;
  return PefZone.red;
}

String severityLabel(int severity) {
  if (severity <= 2) return 'Mild';
  if (severity == 3) return 'Moderate';
  return 'Severe';
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhereOrNull((e) => e.name == name) ?? fallback;
}

DateTime _dt(Object? v, [DateTime? fallback]) {
  if (v is String) return DateTime.tryParse(v) ?? fallback ?? DateTime.now();
  return fallback ?? DateTime.now();
}

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _bool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  return fallback;
}

class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    this.birthYear,
    List<DiagnosisTag>? diagnoses,
    this.otherDiagnosisNote,
    this.peakFlowPersonalBest,
    this.greenPlan = '',
    this.yellowPlan = '',
    this.redPlan = '',
    DateTime? updatedAt,
  }) : diagnoses = diagnoses ?? const [],
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  int? birthYear;
  List<DiagnosisTag> diagnoses;
  String? otherDiagnosisNote;
  int? peakFlowPersonalBest;
  String greenPlan;
  String yellowPlan;
  String redPlan;
  DateTime updatedAt;

  String get diagnosisSummary {
    final hasA = diagnoses.contains(DiagnosisTag.asthma);
    final hasB = diagnoses.contains(DiagnosisTag.bronchitis);
    final hasO = diagnoses.contains(DiagnosisTag.other);
    final parts = <String>[];
    if (hasA && hasB) {
      parts.add('Asthma & bronchitis');
    } else if (hasA) {
      parts.add('Asthma');
    } else if (hasB) {
      parts.add('Bronchitis');
    }
    if (hasO) {
      final extra = otherDiagnosisNote?.trim();
      parts.add((extra == null || extra.isEmpty) ? 'Other' : extra);
    }
    if (parts.isEmpty) return 'Not tagged';
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthYear': birthYear,
    'diagnoses': diagnoses.map((e) => e.name).toList(),
    'otherDiagnosisNote': otherDiagnosisNote,
    'peakFlowPersonalBest': peakFlowPersonalBest,
    'greenPlan': greenPlan,
    'yellowPlan': yellowPlan,
    'redPlan': redPlan,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final raw = (json['diagnoses'] as List?) ?? const [];
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Child',
      birthYear: _int(json['birthYear']),
      diagnoses: raw
          .map(
            (e) => _enumFromName(
              DiagnosisTag.values,
              e.toString(),
              DiagnosisTag.other,
            ),
          )
          .toList(),
      otherDiagnosisNote: json['otherDiagnosisNote'] as String?,
      peakFlowPersonalBest: _int(json['peakFlowPersonalBest']),
      greenPlan: json['greenPlan'] as String? ?? '',
      yellowPlan: json['yellowPlan'] as String? ?? '',
      redPlan: json['redPlan'] as String? ?? '',
      updatedAt: _dt(json['updatedAt']),
    );
  }

  ChildProfile copy() => ChildProfile.fromJson(toJson());
}

class Episode {
  Episode({
    required this.id,
    required this.childId,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.severity = 3,
    this.nighttime = false,
    this.erOrUrgentCare = false,
    this.steroidBurst = false,
    this.notes = '',
    List<TriggerTag>? triggers,
    DateTime? updatedAt,
  }) : triggers = triggers ?? const [],
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String childId;
  EpisodeType type;
  DateTime startedAt;
  DateTime? endedAt;
  int? durationMinutes;
  int severity;
  bool nighttime;
  bool erOrUrgentCare;
  bool steroidBurst;
  String notes;
  List<TriggerTag> triggers;
  DateTime updatedAt;

  int get resolvedDurationMinutes {
    if (durationMinutes != null && durationMinutes! > 0) {
      return durationMinutes!;
    }
    if (endedAt != null) {
      final d = endedAt!.difference(startedAt).inMinutes;
      return d < 0 ? 0 : d;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'type': type.name,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'severity': severity,
    'nighttime': nighttime,
    'erOrUrgentCare': erOrUrgentCare,
    'steroidBurst': steroidBurst,
    'notes': notes,
    'triggers': triggers.map((e) => e.name).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Episode.fromJson(Map<String, dynamic> json) {
    final raw = (json['triggers'] as List?) ?? const [];
    return Episode(
      id: json['id'] as String,
      childId: json['childId'] as String,
      type: _enumFromName(
        EpisodeType.values,
        json['type'] as String?,
        EpisodeType.other,
      ),
      startedAt: _dt(json['startedAt']),
      endedAt: json['endedAt'] == null ? null : _dt(json['endedAt']),
      durationMinutes: _int(json['durationMinutes']),
      severity: (_int(json['severity']) ?? 3).clamp(1, 5),
      nighttime: _bool(json['nighttime']),
      erOrUrgentCare: _bool(json['erOrUrgentCare']),
      steroidBurst: _bool(json['steroidBurst']),
      notes: json['notes'] as String? ?? '',
      triggers: raw
          .map(
            (e) =>
                _enumFromName(TriggerTag.values, e.toString(), TriggerTag.unknown),
          )
          .toList(),
      updatedAt: _dt(json['updatedAt']),
    );
  }
}

class CheckIn {
  CheckIn({
    required this.id,
    required this.childId,
    required this.date,
    this.wheeze = false,
    this.cough = false,
    this.shortnessOfBreath = false,
    this.chestTightness = false,
    this.nightWaking = false,
    this.rescuePuffs = 0,
    this.peakFlow,
    this.notes = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String childId;
  DateTime date;
  bool wheeze;
  bool cough;
  bool shortnessOfBreath;
  bool chestTightness;
  bool nightWaking;
  int rescuePuffs;
  int? peakFlow;
  String notes;
  DateTime updatedAt;

  DateTime get day => DateTime(date.year, date.month, date.day);

  int get symptomCount => [
    wheeze,
    cough,
    shortnessOfBreath,
    chestTightness,
    nightWaking,
  ].where((e) => e).length;

  bool get hasSymptoms => symptomCount > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'date': date.toIso8601String(),
    'wheeze': wheeze,
    'cough': cough,
    'shortnessOfBreath': shortnessOfBreath,
    'chestTightness': chestTightness,
    'nightWaking': nightWaking,
    'rescuePuffs': rescuePuffs,
    'peakFlow': peakFlow,
    'notes': notes,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      childId: json['childId'] as String,
      date: _dt(json['date']),
      wheeze: _bool(json['wheeze']),
      cough: _bool(json['cough']),
      shortnessOfBreath: _bool(json['shortnessOfBreath']),
      chestTightness: _bool(json['chestTightness']),
      nightWaking: _bool(json['nightWaking']),
      rescuePuffs: _int(json['rescuePuffs']) ?? 0,
      peakFlow: _int(json['peakFlow']),
      notes: json['notes'] as String? ?? '',
      updatedAt: _dt(json['updatedAt']),
    );
  }
}

class Medication {
  Medication({
    required this.id,
    required this.childId,
    required this.name,
    this.kind = MedKind.other,
    this.dose = '',
    this.schedule = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String childId;
  String name;
  MedKind kind;
  String dose;
  String schedule;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'name': name,
    'kind': kind.name,
    'dose': dose,
    'schedule': schedule,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      childId: json['childId'] as String,
      name: json['name'] as String? ?? '',
      kind: _enumFromName(MedKind.values, json['kind'] as String?, MedKind.other),
      dose: json['dose'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      updatedAt: _dt(json['updatedAt']),
    );
  }
}

class AppSettings {
  AppSettings({
    this.disclaimerAccepted = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.remindersEnabled = true,
    this.selectedChildId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool disclaimerAccepted;
  int reminderHour;
  int reminderMinute;
  bool remindersEnabled;
  String? selectedChildId;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'disclaimerAccepted': disclaimerAccepted,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'remindersEnabled': remindersEnabled,
    'selectedChildId': selectedChildId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AppSettings();
    return AppSettings(
      disclaimerAccepted: _bool(json['disclaimerAccepted']),
      reminderHour: _int(json['reminderHour']) ?? 20,
      reminderMinute: _int(json['reminderMinute']) ?? 0,
      remindersEnabled: json.containsKey('remindersEnabled')
          ? _bool(json['remindersEnabled'], true)
          : true,
      selectedChildId: json['selectedChildId'] as String?,
      updatedAt: _dt(json['updatedAt']),
    );
  }
}

class AppData {
  AppData({
    List<ChildProfile>? children,
    List<Episode>? episodes,
    List<CheckIn>? checkIns,
    List<Medication>? medications,
    AppSettings? settings,
  }) : children = children ?? [],
       episodes = episodes ?? [],
       checkIns = checkIns ?? [],
       medications = medications ?? [],
       settings = settings ?? AppSettings();

  List<ChildProfile> children;
  List<Episode> episodes;
  List<CheckIn> checkIns;
  List<Medication> medications;
  AppSettings settings;

  bool get isEmpty =>
      children.isEmpty &&
      episodes.isEmpty &&
      checkIns.isEmpty &&
      medications.isEmpty;

  ChildProfile? childById(String? id) =>
      children.firstWhereOrNull((c) => c.id == id);

  List<Episode> episodesFor(String childId) =>
      episodes.where((e) => e.childId == childId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<CheckIn> checkInsFor(String childId) =>
      checkIns.where((e) => e.childId == childId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  CheckIn? checkInOn(String childId, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return checkIns.firstWhereOrNull((c) {
      if (c.childId != childId) return false;
      final cd = c.day;
      return cd == d;
    });
  }

  List<Medication> medsFor(String childId) =>
      medications.where((m) => m.childId == childId).toList();

  Map<String, dynamic> toJson() => {
    'version': 1,
    'children': children.map((e) => e.toJson()).toList(),
    'episodes': episodes.map((e) => e.toJson()).toList(),
    'checkIns': checkIns.map((e) => e.toJson()).toList(),
    'medications': medications.map((e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory AppData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AppData();
    List<Map<String, dynamic>> list(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return AppData(
      children: list('children').map(ChildProfile.fromJson).toList(),
      episodes: list('episodes').map(Episode.fromJson).toList(),
      checkIns: list('checkIns').map(CheckIn.fromJson).toList(),
      medications: list('medications').map(Medication.fromJson).toList(),
      settings: AppSettings.fromJson(
        json['settings'] is Map
            ? Map<String, dynamic>.from(json['settings'] as Map)
            : null,
      ),
    );
  }

  AppData deepCopy() => AppData.fromJson(toJson());

  /// Union by id; keep the record with the later [updatedAt].
  static AppData merge(AppData a, AppData b) {
    T newer<T>(T x, T y, DateTime Function(T) ts) =>
        ts(x).isAfter(ts(y)) ? x : y;

    Map<String, T> mergeList<T>(
      List<T> left,
      List<T> right,
      String Function(T) idOf,
      DateTime Function(T) ts,
    ) {
      final map = <String, T>{};
      for (final item in [...left, ...right]) {
        final id = idOf(item);
        final existing = map[id];
        map[id] = existing == null ? item : newer(existing, item, ts);
      }
      return map;
    }

    final children = mergeList(
      a.children,
      b.children,
      (c) => c.id,
      (c) => c.updatedAt,
    );
    final episodes = mergeList(
      a.episodes,
      b.episodes,
      (e) => e.id,
      (e) => e.updatedAt,
    );
    final checkIns = mergeList(
      a.checkIns,
      b.checkIns,
      (c) => c.id,
      (c) => c.updatedAt,
    );
    final meds = mergeList(
      a.medications,
      b.medications,
      (m) => m.id,
      (m) => m.updatedAt,
    );
    final settings = a.settings.updatedAt.isAfter(b.settings.updatedAt)
        ? a.settings
        : b.settings;
    return AppData(
      children: children.values.toList(),
      episodes: episodes.values.toList(),
      checkIns: checkIns.values.toList(),
      medications: meds.values.toList(),
      settings: settings,
    );
  }
}
