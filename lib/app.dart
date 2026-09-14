import 'package:bronchtracker/screens/home_screen.dart';
import 'package:bronchtracker/screens/insights_screen.dart';
import 'package:bronchtracker/screens/log_screen.dart';
import 'package:bronchtracker/screens/settings_screen.dart';
import 'package:bronchtracker/screens/welcome_screen.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BronchApp extends StatelessWidget {
  const BronchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BronchTracker',
      debugShowCheckedModeBanner: false,
      theme: buildBronchTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    if (ctrl.loading) {
      return const Scaffold(
        backgroundColor: BtColors.cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, size: 48, color: BtColors.sage),
              SizedBox(height: 16),
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading BronchTracker…'),
            ],
          ),
        ),
      );
    }
    if (!ctrl.data.settings.disclaimerAccepted && ctrl.isGuest) {
      return const WelcomeScreen();
    }
    return const ShellScreen();
  }
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;

  static const titles = ['Home', 'Log', 'Insights', 'Kids'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = const [
      HomeScreen(),
      LogScreen(),
      InsightsScreen(),
      SettingsScreen(),
    ];
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Log'),
      NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
      NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: 'Kids'),
    ];

    final body = IndexedStack(index: index, children: pages);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 24),
                child: Column(
                  children: [
                    Icon(Icons.air, color: BtColors.sage, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'BronchTracker',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Log'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: Text('Insights'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.family_restroom_outlined),
                  selectedIcon: Icon(Icons.family_restroom),
                  label: Text('Kids'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  AppBar(title: Text(titles[index])),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'BronchTracker' : titles[index]),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: destinations,
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}
