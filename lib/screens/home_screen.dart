import 'package:bronchtracker/insights/insights.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/screens/editors.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    final child = ctrl.selectedChild;
    if (child == null) {
      return EmptyState(
        icon: Icons.child_care_outlined,
        title: 'Add a child to begin',
        body: 'BronchTracker keeps a parent log per child — episodes, check-ins, and insights.',
        action: FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildEditor()),
          ),
          child: const Text('Add child'),
        ),
      );
    }

    final today = DateTime.now();
    final check = ctrl.data.checkInOn(child.id, today);
    final recent = ctrl.data.episodesFor(child.id).take(4).toList();
    final suggestions = ctrl.suggestionsForSelected();
    final zone = peakFlowZone(check?.peakFlow, child.peakFlowPersonalBest);
    final hour = today.hour;
    final hello = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          hello,
          style: const TextStyle(color: BtColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                child.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: BtColors.ink,
                ),
              ),
            ),
            if (ctrl.data.children.length > 1)
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: child.id,
                  items: [
                    for (final c in ctrl.data.children)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (id) {
                    if (id != null) ctrl.selectChild(id);
                  },
                ),
              ),
          ],
        ),
        Text(
          child.diagnosisSummary +
              (child.birthYear == null ? '' : ' · born ${child.birthYear}'),
          style: const TextStyle(color: BtColors.muted),
        ),
        const SizedBox(height: 14),
        const DisclaimerBanner(compact: true),
        if (ctrl.reminderDue(today)) ...[
          const SizedBox(height: 12),
          BtCard(
            onTap: () => _openCheckIn(context, child, check),
            child: const Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: BtColors.gold),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evening check-in reminder — a quiet day is still worth logging.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        BtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Today'),
              if (check == null)
                const Text(
                  'No check-in yet. A 30-second log keeps Insights honest.',
                  style: TextStyle(height: 1.4),
                )
              else ...[
                Text(
                  check.hasSymptoms
                      ? '${check.symptomCount} symptom${check.symptomCount == 1 ? "" : "s"} · ${check.rescuePuffs} rescue puff${check.rescuePuffs == 1 ? "" : "s"}'
                      : 'Symptoms quiet · ${check.rescuePuffs} rescue puffs',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (check.wheeze) const Chip(label: Text('Wheeze')),
                    if (check.cough) const Chip(label: Text('Cough')),
                    if (check.shortnessOfBreath) const Chip(label: Text('Short of breath')),
                    if (check.chestTightness) const Chip(label: Text('Chest tightness')),
                    if (check.nightWaking) const Chip(label: Text('Night waking')),
                    if (check.peakFlow != null) ZoneChip(zone),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openCheckIn(context, child, check),
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text(check == null ? 'Check in' : 'Update today'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EpisodeEditor(childId: child.id),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log episode'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('Improvement idea'),
          _SuggestionCard(suggestions.first),
        ],
        const SizedBox(height: 16),
        const SectionLabel('Recent episodes'),
        if (recent.isEmpty)
          const Text(
            'No episodes yet. Logging flares and quieter days both help.',
            style: TextStyle(color: BtColors.muted),
          )
        else
          ...recent.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BtCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EpisodeEditor(childId: child.id, existing: e),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: BtColors.sageSoft,
                    foregroundColor: BtColors.sageDark,
                    child: Text('${e.severity}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.type.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          DateFormat.MMMd().add_jm().format(e.startedAt) +
                              (e.nighttime ? ' · night' : '') +
                              (e.erOrUrgentCare ? ' · ER/UC' : ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: BtColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: BtColors.muted),
                ],
              ),
            ),
          )),
      ],
    );
  }

  void _openCheckIn(BuildContext context, ChildProfile child, CheckIn? check) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckInEditor(child: child, existing: check),
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard(this.item, {super.key});
  final Suggestion item;

  @override
  Widget build(BuildContext context) => _SuggestionCard(item);
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard(this.item);
  final Suggestion item;

  @override
  Widget build(BuildContext context) {
    return BtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: BtColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.body, style: const TextStyle(height: 1.4, fontSize: 13.5)),
          const SizedBox(height: 8),
          const Text(
            'Educational only — never a diagnosis or prescription.',
            style: TextStyle(fontSize: 11, color: BtColors.muted),
          ),
        ],
      ),
    );
  }
}
