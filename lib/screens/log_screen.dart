import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/screens/editors.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late DateTime visibleMonth;
  DateTime? selectedDay;
  EpisodeType? typeFilter;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    visibleMonth = DateTime(n.year, n.month);
    selectedDay = DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    final child = ctrl.selectedChild;
    if (child == null) {
      return const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No child selected',
        body: 'Add a child in Kids / Settings first.',
      );
    }

    final episodes = ctrl.data.episodesFor(child.id).where((e) {
      if (typeFilter == null) return true;
      return e.type == typeFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(visibleMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _MonthGrid(
            month: visibleMonth,
            selected: selectedDay,
            episodeDays: {
              for (final e in ctrl.data.episodesFor(child.id))
                DateTime(e.startedAt.year, e.startedAt.month, e.startedAt.day),
            },
            checkInDays: {
              for (final c in ctrl.data.checkInsFor(child.id)) c.day,
            },
            onSelect: (d) => setState(() => selectedDay = d),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('All types'),
                  selected: typeFilter == null,
                  onSelected: (_) => setState(() => typeFilter = null),
                ),
              ),
              for (final t in EpisodeType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t.shortLabel),
                    selected: typeFilter == t,
                    onSelected: (_) => setState(() => typeFilter = t),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            children: [
              if (selectedDay != null) _DayPanel(child: child, day: selectedDay!),
              const SizedBox(height: 12),
              const SectionLabel('Episode list'),
              if (episodes.isEmpty)
                const Text(
                  'No episodes in this filter.',
                  style: TextStyle(color: BtColors.muted),
                )
              else
                for (final e in episodes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BtCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EpisodeEditor(childId: child.id, existing: e),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.type.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().add_jm().format(e.startedAt),
                            style: const TextStyle(
                              color: BtColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SeverityDots(e.severity),
                          if (e.triggers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 6,
                                children: [
                                  for (final t in e.triggers)
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(t.label, style: const TextStyle(fontSize: 11)),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.child, required this.day});
  final ChildProfile child;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    final check = ctrl.data.checkInOn(child.id, day);
    final eps = ctrl.data
        .episodesFor(child.id)
        .where(
          (e) =>
              e.startedAt.year == day.year &&
              e.startedAt.month == day.month &&
              e.startedAt.day == day.day,
        )
        .toList();
    return BtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMMEEEEd().format(day),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            check == null
                ? 'No check-in'
                : 'Check-in · ${check.symptomCount} symptoms · ${check.rescuePuffs} puffs'
                  '${check.peakFlow != null ? " · PEF ${check.peakFlow}" : ""}',
          ),
          if (eps.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No episodes this day', style: TextStyle(color: BtColors.muted)),
            )
          else
            for (final e in eps)
              Text('• ${e.type.shortLabel} (severity ${e.severity})'),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckInEditor(
                      child: child,
                      existing: check,
                      day: day,
                    ),
                  ),
                ),
                child: const Text('Check-in'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EpisodeEditor(childId: child.id),
                  ),
                ),
                child: const Text('Add episode'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.episodeDays,
    required this.checkInDays,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selected;
  final Set<DateTime> episodeDays;
  final Set<DateTime> checkInDays;
  final ValueChanged<DateTime> onSelect;

  bool _has(Set<DateTime> set, DateTime d) =>
      set.any((x) => x.year == d.year && x.month == d.month && x.day == d.day);

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7; // Sunday-start
    final cells = lead + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    return Column(
      children: [
        Row(
          children: [
            for (final w in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BtColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c, lead, daysInMonth)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int index, int lead, int daysInMonth) {
    final dayNum = index - lead + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 42);
    }
    final d = DateTime(month.year, month.month, dayNum);
    final isSel = selected != null &&
        selected!.year == d.year &&
        selected!.month == d.month &&
        selected!.day == d.day;
    return InkWell(
      onTap: () => onSelect(d),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? BtColors.sage : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : BtColors.ink,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_has(checkInDays, d))
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: const BoxDecoration(
                      color: BtColors.sage,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (_has(episodeDays, d))
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: BtColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
