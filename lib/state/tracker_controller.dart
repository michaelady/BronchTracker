import 'package:bronchtracker/data/app_repository.dart';
import 'package:bronchtracker/data/demo_data.dart';
import 'package:bronchtracker/firebase_boot.dart';
import 'package:bronchtracker/insights/insights.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TrackerController extends ChangeNotifier {
  TrackerController(this.repo);

  final AppRepository repo;

  AppData data = AppData();
  bool loading = true;
  bool firebaseReady = false;
  String? authError;
  User? user;
  StatsPeriod period = StatsPeriod.month;

  ChildProfile? get selectedChild {
    final id = data.settings.selectedChildId;
    return data.childById(id) ?? (data.children.isEmpty ? null : data.children.first);
  }

  bool get isGuest => user == null;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    firebaseReady = FirebaseBoot.ready;
    if (firebaseReady) {
      user = FirebaseAuth.instance.currentUser;
      FirebaseAuth.instance.authStateChanges().listen((u) {
        user = u;
        notifyListeners();
      });
    }
    data = await repo.loadMerged();
    if (firebaseReady && user != null && !data.isEmpty) {
      await repo.persist(data);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _commit() async {
    data.settings.updatedAt = DateTime.now();
    notifyListeners();
    await repo.persist(data);
  }

  Future<void> acceptDisclaimer() async {
    data.settings.disclaimerAccepted = true;
    await _commit();
  }

  Future<void> enterGuest({required bool seedDemo}) async {
    if (seedDemo && data.children.isEmpty) {
      data = buildDemoData(DateTime.now());
    }
    data.settings.disclaimerAccepted = true;
    user = null;
    await _commit();
  }

  Future<void> seedDemoFamily() async {
    data = buildDemoData(DateTime.now());
    await _commit();
  }

  Future<void> signInGoogle() async {
    authError = null;
    notifyListeners();
    try {
      await repo.signInWithGoogle();
      user = FirebaseAuth.instance.currentUser;
      final merged = await repo.loadMerged();
      data = merged;
      data.settings.disclaimerAccepted = true;
      await repo.persist(data);
    } catch (e) {
      authError = e.toString();
    }
    notifyListeners();
  }

  Future<void> signOutKeepLocal() async {
    await repo.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> selectChild(String id) async {
    data.settings.selectedChildId = id;
    await _commit();
  }

  Future<void> upsertChild(ChildProfile child) async {
    final i = data.children.indexWhere((c) => c.id == child.id);
    child.updatedAt = DateTime.now();
    if (i >= 0) {
      data.children[i] = child;
    } else {
      data.children.add(child);
    }
    data.settings.selectedChildId = child.id;
    await _commit();
  }

  Future<void> deleteChild(String id) async {
    data.children.removeWhere((c) => c.id == id);
    data.episodes.removeWhere((e) => e.childId == id);
    data.checkIns.removeWhere((c) => c.childId == id);
    data.medications.removeWhere((m) => m.childId == id);
    if (data.settings.selectedChildId == id) {
      data.settings.selectedChildId = data.children.isEmpty
          ? null
          : data.children.first.id;
    }
    await _commit();
  }

  Future<void> upsertEpisode(Episode episode) async {
    episode.updatedAt = DateTime.now();
    final i = data.episodes.indexWhere((e) => e.id == episode.id);
    if (i >= 0) {
      data.episodes[i] = episode;
    } else {
      data.episodes.add(episode);
    }
    await _commit();
  }

  Future<void> deleteEpisode(String id) async {
    data.episodes.removeWhere((e) => e.id == id);
    await _commit();
  }

  Future<void> upsertCheckIn(CheckIn incoming) async {
    final day = incoming.day;
    final existing = data.checkIns.indexWhere(
      (c) => c.childId == incoming.childId && c.day == day,
    );
    final saved = CheckIn(
      id: existing >= 0 ? data.checkIns[existing].id : incoming.id,
      childId: incoming.childId,
      date: incoming.date,
      wheeze: incoming.wheeze,
      cough: incoming.cough,
      shortnessOfBreath: incoming.shortnessOfBreath,
      chestTightness: incoming.chestTightness,
      nightWaking: incoming.nightWaking,
      rescuePuffs: incoming.rescuePuffs,
      peakFlow: incoming.peakFlow,
      notes: incoming.notes,
      updatedAt: DateTime.now(),
    );
    if (existing >= 0) {
      data.checkIns[existing] = saved;
    } else {
      data.checkIns.add(saved);
    }
    await _commit();
  }

  Future<void> upsertMed(Medication med) async {
    med.updatedAt = DateTime.now();
    final i = data.medications.indexWhere((m) => m.id == med.id);
    if (i >= 0) {
      data.medications[i] = med;
    } else {
      data.medications.add(med);
    }
    await _commit();
  }

  Future<void> deleteMed(String id) async {
    data.medications.removeWhere((m) => m.id == id);
    await _commit();
  }

  Future<void> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    data.settings.remindersEnabled = enabled;
    data.settings.reminderHour = hour;
    data.settings.reminderMinute = minute;
    await _commit();
  }

  Future<void> setPeriod(StatsPeriod p) async {
    period = p;
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    data = AppData(
      settings: AppSettings(disclaimerAccepted: true, updatedAt: DateTime.now()),
    );
    await repo.clearLocal();
    await repo.persist(data);
    notifyListeners();
  }

  ChildStats? statsForSelected([DateTime? now]) {
    final child = selectedChild;
    if (child == null) return null;
    return computeStats(
      child: child,
      episodes: data.episodes,
      checkIns: data.checkIns,
      medications: data.medications,
      period: period,
      now: now ?? DateTime.now(),
    );
  }

  List<Suggestion> suggestionsForSelected([DateTime? now]) {
    final child = selectedChild;
    final stats = statsForSelected(now);
    if (child == null || stats == null) return const [];
    return proposeImprovements(
      child: child,
      stats: stats,
      episodes: data.episodes,
      checkIns: data.checkIns,
    );
  }

  bool reminderDue(DateTime now) {
    if (!data.settings.remindersEnabled) return false;
    final child = selectedChild;
    if (child == null) return false;
    if (data.checkInOn(child.id, now) != null) return false;
    final t = DateTime(
      now.year,
      now.month,
      now.day,
      data.settings.reminderHour,
      data.settings.reminderMinute,
    );
    return !now.isBefore(t);
  }
}
