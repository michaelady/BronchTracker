import 'package:bronchtracker/data/demo_data.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EpisodeEditor extends StatefulWidget {
  const EpisodeEditor({super.key, required this.childId, this.existing});

  final String childId;
  final Episode? existing;

  @override
  State<EpisodeEditor> createState() => _EpisodeEditorState();
}

class _EpisodeEditorState extends State<EpisodeEditor> {
  late EpisodeType type;
  late DateTime started;
  TimeOfDay time;
  int durationMinutes = 30;
  int severity = 3;
  bool nighttime = false;
  bool er = false;
  bool steroid = false;
  final notes = TextEditingController();
  final selected = <TriggerTag>{};

  _EpisodeEditorState() : time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    type = e?.type ?? EpisodeType.wheeze;
    started = e?.startedAt ?? DateTime.now();
    time = TimeOfDay(hour: started.hour, minute: started.minute);
    durationMinutes = e?.resolvedDurationMinutes == 0
        ? 30
        : (e?.resolvedDurationMinutes ?? 30);
    severity = e?.severity ?? 3;
    nighttime = e?.nighttime ?? false;
    er = e?.erOrUrgentCare ?? false;
    steroid = e?.steroidBurst ?? false;
    notes.text = e?.notes ?? '';
    selected.addAll(e?.triggers ?? const []);
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Log episode' : 'Edit episode'),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                await context.read<TrackerController>().deleteEpisode(
                  widget.existing!.id,
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const DisclaimerBanner(compact: true),
          const SizedBox(height: 16),
          const SectionLabel('Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in EpisodeType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: type == t,
                  onSelected: (_) => setState(() => type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('When'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: started,
                      firstDate: DateTime(nowYear() - 5),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) {
                      setState(() {
                        started = DateTime(d.year, d.month, d.day, time.hour, time.minute);
                      });
                    }
                  },
                  child: Text(df.format(started)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: time);
                    if (t != null) {
                      setState(() {
                        time = t;
                        started = DateTime(
                          started.year,
                          started.month,
                          started.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    }
                  },
                  child: Text(time.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Duration: $durationMinutes min'),
          Slider(
            value: durationMinutes.toDouble().clamp(5, 240),
            min: 5,
            max: 240,
            divisions: 47,
            label: '$durationMinutes min',
            onChanged: (v) => setState(() => durationMinutes = v.round()),
          ),
          const SectionLabel('Severity (1 mild – 5 severe)'),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$i'),
                    selected: severity == i,
                    onSelected: (_) => setState(() => severity = i),
                  ),
                ),
              Text(severityLabel(severity)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nighttime episode'),
            value: nighttime,
            onChanged: (v) => setState(() => nighttime = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ER or urgent care'),
            value: er,
            onChanged: (v) => setState(() => er = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Steroid burst'),
            subtitle: const Text('Oral/systemic course, if one was given'),
            value: steroid,
            onChanged: (v) => setState(() => steroid = v),
          ),
          const SectionLabel('Triggers'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TriggerTag.values)
                FilterChip(
                  label: Text(t.label),
                  selected: selected.contains(t),
                  onSelected: (v) => setState(() {
                    if (v) {
                      selected.add(t);
                    } else {
                      selected.remove(t);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'What you noticed, what you did (not medical advice)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final episode = Episode(
                id: widget.existing?.id ?? newId(),
                childId: widget.childId,
                type: type,
                startedAt: started,
                durationMinutes: durationMinutes,
                endedAt: started.add(Duration(minutes: durationMinutes)),
                severity: severity,
                nighttime: nighttime,
                erOrUrgentCare: er,
                steroidBurst: steroid,
                notes: notes.text.trim(),
                triggers: selected.toList(),
              );
              await context.read<TrackerController>().upsertEpisode(episode);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save episode'),
          ),
        ],
      ),
    );
  }
}

int nowYear() => DateTime.now().year;

class CheckInEditor extends StatefulWidget {
  const CheckInEditor({
    super.key,
    required this.child,
    this.existing,
    this.day,
  });

  final ChildProfile child;
  final CheckIn? existing;
  final DateTime? day;

  @override
  State<CheckInEditor> createState() => _CheckInEditorState();
}

class _CheckInEditorState extends State<CheckInEditor> {
  late bool wheeze;
  late bool cough;
  late bool sob;
  late bool tight;
  late bool night;
  late int puffs;
  final pef = TextEditingController();
  final notes = TextEditingController();
  late DateTime date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    date = e?.date ?? widget.day ?? DateTime.now();
    wheeze = e?.wheeze ?? false;
    cough = e?.cough ?? false;
    sob = e?.shortnessOfBreath ?? false;
    tight = e?.chestTightness ?? false;
    night = e?.nightWaking ?? false;
    puffs = e?.rescuePuffs ?? 0;
    if (e?.peakFlow != null) pef.text = '${e!.peakFlow}';
    notes.text = e?.notes ?? '';
  }

  @override
  void dispose() {
    pef.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pefVal = int.tryParse(pef.text.trim());
    final zone = peakFlowZone(pefVal, widget.child.peakFlowPersonalBest);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily check-in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            DateFormat.yMMMMEEEEd().format(date),
            style: const TextStyle(color: BtColors.muted),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Symptoms today'),
          _sym('Wheeze', wheeze, (v) => setState(() => wheeze = v)),
          _sym('Cough', cough, (v) => setState(() => cough = v)),
          _sym('Shortness of breath', sob, (v) => setState(() => sob = v)),
          _sym('Chest tightness', tight, (v) => setState(() => tight = v)),
          _sym('Night waking', night, (v) => setState(() => night = v)),
          const SizedBox(height: 8),
          const SectionLabel('Rescue inhaler puffs'),
          Row(
            children: [
              IconButton(
                onPressed: puffs == 0 ? null : () => setState(() => puffs--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$puffs', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => setState(() => puffs++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SectionLabel('Peak flow (optional, L/min)'),
          TextField(
            controller: pef,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.child.peakFlowPersonalBest == null
                  ? 'Manual entry'
                  : 'Personal best ${widget.child.peakFlowPersonalBest}',
            ),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: ZoneChip(zone)),
          if (widget.child.peakFlowPersonalBest != null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Green ≥80% of personal best · yellow 50–80% · red <50%. Home diary only.',
                style: TextStyle(fontSize: 12, color: BtColors.muted),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await context.read<TrackerController>().upsertCheckIn(
                CheckIn(
                  id: widget.existing?.id ?? newId(),
                  childId: widget.child.id,
                  date: date,
                  wheeze: wheeze,
                  cough: cough,
                  shortnessOfBreath: sob,
                  chestTightness: tight,
                  nightWaking: night,
                  rescuePuffs: puffs,
                  peakFlow: int.tryParse(pef.text.trim()),
                  notes: notes.text.trim(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save check-in'),
          ),
        ],
      ),
    );
  }

  Widget _sym(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class ChildEditor extends StatefulWidget {
  const ChildEditor({super.key, this.existing});
  final ChildProfile? existing;

  @override
  State<ChildEditor> createState() => _ChildEditorState();
}

class _ChildEditorState extends State<ChildEditor> {
  final name = TextEditingController();
  final year = TextEditingController();
  final other = TextEditingController();
  final pef = TextEditingController();
  final green = TextEditingController();
  final yellow = TextEditingController();
  final red = TextEditingController();
  final tags = <DiagnosisTag>{};

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      name.text = c.name;
      if (c.birthYear != null) year.text = '${c.birthYear}';
      other.text = c.otherDiagnosisNote ?? '';
      if (c.peakFlowPersonalBest != null) pef.text = '${c.peakFlowPersonalBest}';
      green.text = c.greenPlan;
      yellow.text = c.yellowPlan;
      red.text = c.redPlan;
      tags.addAll(c.diagnoses);
    }
  }

  @override
  void dispose() {
    name.dispose();
    year.dispose();
    other.dispose();
    pef.dispose();
    green.dispose();
    yellow.dispose();
    red.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add child' : 'Edit ${widget.existing!.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Birth year (optional)',
              hintText: 'e.g. 2018',
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Diagnosis tags'),
          Wrap(
            spacing: 8,
            children: [
              for (final t in DiagnosisTag.values)
                FilterChip(
                  label: Text(t.label),
                  selected: tags.contains(t),
                  onSelected: (v) => setState(() {
                    if (v) {
                      tags.add(t);
                    } else {
                      tags.remove(t);
                    }
                  }),
                ),
            ],
          ),
          if (tags.contains(DiagnosisTag.other)) ...[
            const SizedBox(height: 8),
            TextField(
              controller: other,
              decoration: const InputDecoration(labelText: 'Other diagnosis note'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: pef,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peak-flow personal best (optional, L/min)',
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Action plan notes (your clinician’s plan, in your words)'),
          TextField(
            controller: green,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Green zone — what to do'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: yellow,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Yellow zone — what to do'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: red,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Red zone — what to do (call emergency services if severe)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) {
                await showBtMessage(context, 'Please enter a name.');
                return;
              }
              final profile = ChildProfile(
                id: widget.existing?.id ?? newId(),
                name: name.text.trim(),
                birthYear: int.tryParse(year.text.trim()),
                diagnoses: tags.toList(),
                otherDiagnosisNote: other.text.trim().isEmpty ? null : other.text.trim(),
                peakFlowPersonalBest: int.tryParse(pef.text.trim()),
                greenPlan: green.text.trim(),
                yellowPlan: yellow.text.trim(),
                redPlan: red.text.trim(),
              );
              await context.read<TrackerController>().upsertChild(profile);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save child'),
          ),
        ],
      ),
    );
  }
}
