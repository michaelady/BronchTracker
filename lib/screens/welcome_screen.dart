import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool seedDemo = true;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: BtColors.sageSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.air,
                      color: BtColors.sageDark,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BronchTracker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: BtColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A calm parent log for kids’ bronchitis flares, asthma exacerbations, and everyday breathing days.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: BtColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                const DisclaimerBanner(),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: seedDemo,
                  onChanged: (v) => setState(() => seedDemo = v),
                  title: const Text('Load sample family (for Tester)'),
                  subtitle: const Text(
                    'Alex & Sam with episodes, check-ins, meds, and action-plan notes. You can delete this anytime.',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          await ctrl.enterGuest(seedDemo: seedDemo);
                          if (mounted) setState(() => busy = false);
                        },
                  child: Text(
                    seedDemo ? 'Continue as guest with demo data' : 'Continue as guest',
                  ),
                ),
                const SizedBox(height: 10),
                if (ctrl.firebaseReady)
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            await ctrl.signInGoogle();
                            if (mounted) setState(() => busy = false);
                          },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google (sync)'),
                  )
                else
                  const Text(
                    'Google Sign-In sync turns on when Firebase is configured. Guest mode stores data on this device only.',
                    style: TextStyle(fontSize: 13, color: BtColors.muted, height: 1.4),
                  ),
                if (ctrl.authError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    ctrl.authError!,
                    style: const TextStyle(color: BtColors.coral, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  'No ads. Kids’ health data is not sold. Easy delete lives in Settings.',
                  style: TextStyle(fontSize: 13, color: BtColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
