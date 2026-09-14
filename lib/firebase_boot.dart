import 'package:bronchtracker/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Attempts Firebase init when [DefaultFirebaseOptions] is not a placeholder.
/// Guest mode works without this.
class FirebaseBoot {
  FirebaseBoot._();

  static bool ready = false;
  static String? lastError;

  static Future<bool> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      ready = false;
      lastError = null;
      return false;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      ready = true;
      lastError = null;
      return true;
    } catch (e, st) {
      ready = false;
      lastError = e.toString();
      debugPrint('Firebase init skipped: $e\n$st');
      return false;
    }
  }
}
