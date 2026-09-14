import 'package:bronchtracker/data/demo_data.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/screens/editors.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    final child = ctrl.selectedChild;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text(
          'Kids & settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: BtColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ctrl.isGuest
              ? 'Guest mode · data stays on this device'
              : 'Signed in as ${ctrl.user?.email ?? ctrl.user?.uid}',
          style: const TextStyle(color: BtColors.muted),
        ),
        const SizedBox(height: 16),
        const DisclaimerBanner(),
        const SizedBox(height: 16),
        const SectionLabel('Children'),
        for (final c in ctrl.data.children)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BtCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChildEditor(existing: c)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: c.id == child?.id
                        ? BtColors.sage
                        : BtColors.sageSoft,
                    foregroundColor: c.id == child?.id
                        ? Colors.white
                        : BtColors.sageDark,
                    child: Text(
                      c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          c.diagnosisSummary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: BtColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ctrl.selectChild(c.id),
                    child: Text(c.id == child?.id ? 'Selected' : 'Select'),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildEditor()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add child'),
        ),
        if (child != null) ...[
          const SizedBox(height: 20),
          const SectionLabel('Medications for selected child'),
          for (final m in ctrl.data.medsFor(child.id))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.name),
              subtitle: Text(
                '${m.kind.label}${m.dose.isEmpty ? "" : " · ${m.dose}"}${m.schedule.isEmpty ? "" : " · ${m.schedule}"}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ctrl.deleteMed(m.id),
              ),
              onTap: () => _medDialog(context, child.id, m),
            ),
          TextButton.icon(
            onPressed: () => _medDialog(context, child.id, null),
            icon: const Icon(Icons.add),
            label: const Text('Add medication'),
          ),
          const SectionLabel('Action plan (selected child)'),
          _PlanPreview(title: 'Green', body: child.greenPlan, color: BtColors.greenZone),
          _PlanPreview(title: 'Yellow', body: child.yellowPlan, color: BtColors.yellowZone),
          _PlanPreview(title: 'Red', body: child.redPlan, color: BtColors.redZone),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChildEditor(existing: child)),
            ),
            child: const Text('Edit action plan & personal best'),
          ),
        ],
        const SizedBox(height: 12),
        const SectionLabel('Check-in reminder (local stub)'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show a home reminder after this time'),
          subtitle: const Text(
            'Works on web and Android without extra permissions. Not a medical alarm.',
          ),
          value: ctrl.data.settings.remindersEnabled,
          onChanged: (v) => ctrl.setReminder(
            enabled: v,
            hour: ctrl.data.settings.reminderHour,
            minute: ctrl.data.settings.reminderMinute,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reminder time'),
          subtitle: Text(
            TimeOfDay(
              hour: ctrl.data.settings.reminderHour,
              minute: ctrl.data.settings.reminderMinute,
            ).format(context),
          ),
          trailing: const Icon(Icons.schedule),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: ctrl.data.settings.reminderHour,
                minute: ctrl.data.settings.reminderMinute,
              ),
            );
            if (t != null) {
              await ctrl.setReminder(
                enabled: ctrl.data.settings.remindersEnabled,
                hour: t.hour,
                minute: t.minute,
              );
            }
          },
        ),
        const SizedBox(height: 8),
        const SectionLabel('Account'),
        if (ctrl.firebaseReady && ctrl.isGuest)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login),
            title: const Text('Sign in with Google'),
            subtitle: const Text('Sync this diary to Firestore'),
            onTap: () => ctrl.signInGoogle(),
          )
        else if (!ctrl.firebaseReady)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Cloud sync not configured'),
            subtitle: Text('See README to add Firebase. Guest mode still works.'),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            subtitle: const Text('Keeps a copy on this device'),
            onTap: () => ctrl.signOutKeepLocal(),
          ),
        if (ctrl.authError != null)
          Text(ctrl.authError!, style: const TextStyle(color: BtColors.coral)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.science_outlined),
          title: const Text('Reload tester demo family'),
          subtitle: const Text('Replaces current local+cloud snapshot with sample kids'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Load demo data?'),
                content: const Text(
                  'This replaces the current diary with the sample family (Alex & Sam).',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Load demo'),
                  ),
                ],
              ),
            );
            if (ok == true) await ctrl.seedDemoFamily();
          },
        ),
        const SectionLabel('Privacy'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_forever_outlined, color: BtColors.coral),
          title: const Text('Delete all diary data'),
          subtitle: const Text('Clears kids, episodes, check-ins, and meds on this account/device'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete everything?'),
                content: const Text(
                  'This cannot be undone from the app. Export a visit summary first if you need a copy.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete all'),
                  ),
                ],
              ),
            );
            if (ok == true) await ctrl.deleteAllData();
          },
        ),
        if (child != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_off_outlined),
            title: Text('Delete ${child.name} only'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete ${child.name}?'),
                  content: const Text(
                    'Removes this child and their episodes, check-ins, and meds.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) await ctrl.deleteChild(child.id);
            },
          ),
        const SizedBox(height: 16),
        const Text(
          'BronchTracker 1.0 · Not a medical device · No ads · Data is not sold.',
          style: TextStyle(fontSize: 12, color: BtColors.muted),
        ),
      ],
    );
  }

  Future<void> _medDialog(
    BuildContext context,
    String childId,
    Medication? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final dose = TextEditingController(text: existing?.dose ?? '');
    final schedule = TextEditingController(text: existing?.schedule ?? '');
    var kind = existing?.kind ?? MedKind.controller;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: Text(existing == null ? 'Add medication' : 'Edit medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MedKind>(
                      initialValue: kind,
                      items: [
                        for (final k in MedKind.values)
                          DropdownMenuItem(value: k, child: Text(k.label)),
                      ],
                      onChanged: (v) => setSt(() => kind = v ?? kind),
                      decoration: const InputDecoration(labelText: 'Kind'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dose,
                      decoration: const InputDecoration(
                        labelText: 'Dose note (your clinician’s instructions)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: schedule,
                      decoration: const InputDecoration(labelText: 'Schedule note'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty) return;
                    await context.read<TrackerController>().upsertMed(
                      Medication(
                        id: existing?.id ?? newId(),
                        childId: childId,
                        name: name.text.trim(),
                        kind: kind,
                        dose: dose.text.trim(),
                        schedule: schedule.text.trim(),
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({
    required this.title,
    required this.body,
    required this.color,
  });
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              body.isEmpty ? 'No notes yet — add your clinician’s plan in your own words.' : body,
              style: const TextStyle(height: 1.35, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'BronchTracker privacy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            'BronchTracker is a parent-facing breathing diary for children. '
            'It is not a medical device, not emergency care, and not a seller of kids’ health data.',
            style: TextStyle(height: 1.45),
          ),
          SizedBox(height: 12),
          Text(
            'What we store',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Child profiles, episodes, daily check-ins, medications, action-plan notes, '
            'and reminder preferences. Guest mode keeps this in the browser or on-device store only. '
            'If you enable Google Sign-In with a configured Firebase project, the same diary is '
            'written to your Firebase Authentication user document in Cloud Firestore.',
            style: TextStyle(height: 1.45),
          ),
          SizedBox(height: 12),
          Text(
            'What we do not do',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'No ads. No sale of personal or health information. No sharing with data brokers. '
            'No smart-inhaler hardware collection in this MVP.',
            style: TextStyle(height: 1.45),
          ),
          SizedBox(height: 12),
          Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Use Kids / Settings → Delete all diary data (or delete one child). '
            'That clears local storage and, when signed in, the cloud document for your user.',
            style: TextStyle(height: 1.45),
          ),
          SizedBox(height: 12),
          Text(
            'Emergency',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            medicalDisclaimer,
            style: TextStyle(height: 1.45),
          ),
        ],
      ),
    );
  }
}
