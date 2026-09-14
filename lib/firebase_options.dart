// Placeholder Firebase options. Replace with `flutterfire configure` output.
// Until then, BronchTracker runs fully in guest / local mode.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured {
    final key = web.apiKey;
    return key.isNotEmpty && !key.startsWith('REPLACE_');
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'BronchTracker Firebase is documented for web and Android. '
          'Run flutterfire configure for other platforms.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WEB_API_KEY',
    appId: 'REPLACE_WEB_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'bronchtracker-placeholder',
    authDomain: 'bronchtracker-placeholder.firebaseapp.com',
    storageBucket: 'bronchtracker-placeholder.appspot.com',
    measurementId: 'REPLACE_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ANDROID_API_KEY',
    appId: 'REPLACE_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'bronchtracker-placeholder',
    storageBucket: 'bronchtracker-placeholder.appspot.com',
  );
}
