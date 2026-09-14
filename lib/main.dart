import 'package:bronchtracker/app.dart';
import 'package:bronchtracker/configure_url.dart'
    if (dart.library.html) 'package:bronchtracker/configure_url_web.dart';
import 'package:bronchtracker/data/app_repository.dart';
import 'package:bronchtracker/firebase_boot.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await FirebaseBoot.initialize();
  final prefs = await SharedPreferences.getInstance();
  final repo = AppRepository(prefs);
  final controller = TrackerController(repo);
  await controller.bootstrap();
  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const BronchApp(),
    ),
  );
}
