import 'package:bronchtracker/app.dart';
import 'package:bronchtracker/data/app_repository.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('guest demo reaches home with Alex and disclaimer', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ctrl = TrackerController(AppRepository(prefs));
    await ctrl.bootstrap();
    await ctrl.enterGuest(seedDemo: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ctrl,
        child: const BronchApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp('not a medical device', caseSensitive: false)), findsWidgets);
    expect(find.text('Alex'), findsWidgets);
    expect(find.text('Log episode'), findsWidgets);
    expect(find.textContaining('Update today'), findsWidgets);
  });

  testWidgets('welcome screen offers guest path', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ctrl = TrackerController(AppRepository(prefs));
    await ctrl.bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ctrl,
        child: const BronchApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BronchTracker'), findsWidgets);
    expect(find.textContaining('Continue as guest'), findsOneWidget);
    expect(find.textContaining('sample family'), findsWidgets);
    expect(find.textContaining(RegExp('not a medical device', caseSensitive: false)), findsWidgets);
  });
}
