import 'dart:convert';

import 'package:bronchtracker/firebase_boot.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localDataKey = 'bronchtracker.appData.v1';
const guestUid = 'guest-local';

class AppRepository {
  AppRepository(this.prefs);

  final SharedPreferences prefs;

  String get activeUid =>
      FirebaseBoot.ready ? (FirebaseAuth.instance.currentUser?.uid ?? guestUid) : guestUid;

  bool get isCloudUser =>
      FirebaseBoot.ready && FirebaseAuth.instance.currentUser != null;

  String? get email => FirebaseAuth.instance.currentUser?.email;

  String? get displayName => FirebaseAuth.instance.currentUser?.displayName;

  Future<AppData> loadLocal() async {
    final raw = prefs.getString(localDataKey);
    if (raw == null || raw.isEmpty) return AppData();
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Local data parse failed: $e');
      return AppData();
    }
  }

  Future<void> saveLocal(AppData data) async {
    await prefs.setString(localDataKey, jsonEncode(data.toJson()));
  }

  Future<void> clearLocal() async {
    await prefs.remove(localDataKey);
  }

  DocumentReference<Map<String, dynamic>> _root(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<AppData> loadCloud(String uid) async {
    final snap = await _root(uid).get();
    if (!snap.exists || snap.data() == null) return AppData();
    return AppData.fromJson(snap.data());
  }

  Future<void> saveCloud(String uid, AppData data) async {
    await _root(uid).set({
      ...data.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<AppData> loadMerged() async {
    final local = await loadLocal();
    if (!isCloudUser) return local;
    try {
      final cloud = await loadCloud(FirebaseAuth.instance.currentUser!.uid);
      if (cloud.isEmpty) return local;
      if (local.isEmpty) return cloud;
      return AppData.merge(local, cloud);
    } catch (e) {
      debugPrint('Cloud load failed, using local: $e');
      return local;
    }
  }

  Future<void> persist(AppData data) async {
    await saveLocal(data);
    if (!isCloudUser) return;
    try {
      await saveCloud(FirebaseAuth.instance.currentUser!.uid, data);
    } catch (e) {
      debugPrint('Cloud save failed (local kept): $e');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!FirebaseBoot.ready) {
      throw StateError('Firebase is not configured.');
    }
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(provider);
    }
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // initialize is idempotent; ignore repeat calls
    }
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final cred = GoogleAuthProvider.credential(idToken: idToken);
      return FirebaseAuth.instance.signInWithCredential(cred);
    }
    return FirebaseAuth.instance.signInWithProvider(provider);
  }

  Future<void> signOut() async {
    if (!FirebaseBoot.ready) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
