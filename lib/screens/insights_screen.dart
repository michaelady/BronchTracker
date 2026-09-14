import 'package:bronchtracker/insights/insights.dart';
import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/screens/home_screen.dart';
import 'package:bronchtracker/state/tracker_controller.dart';
import 'package:bronchtracker/theme.dart';
import 'package:bronchtracker/widgets/common.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TrackerController>();
    final child = ctrl.selectedChild;
    if (child == null) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'Insights need a child log',
        body: 'Add a child and a few episodes or check-ins to see patterns.',
      );
    }
    final stats = ctrl.statsForSelected()!;
    final suggestions = ctrl.suggestionsForSelected();
    final periodLabel = switch (ctrl.period) {
      StatsPeriod.week => '7 days',
      StatsPeriod.month => '30 days',
      StatsPeriod.season => '${seasonName(DateTime.now())} season',
      StatsPeriod.year => '12 months',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          '${child.name} · $periodLabel',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: BtColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Patterns from your diary — educational, not a diagnosis.',
          style: TextStyle(color: BtColors.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final p in StatsPeriod.values)
              ChoiceChip(
                label: Text(switch (p) {
                  StatsPeriod.week => 'Week',
                  StatsPeriod.month => 'Month',
                  StatsPeriod.season => 'Season',
                  StatsPeriod.year => 'Year',
                }),
                selected: ctrl.period == p,
                onSelected: (_) => ctrl.setPeriod(p),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatTile(
              label: 'Episodes',
              value: '${stats.episodeCount}',
              hint: '${stats.episodesPerWeek.toStringAsFixed(1)} / week',
            ),
            _StatTile(
              label: 'Avg severity',
              value: stats.episodeCount == 0 ? '—' : stats.avgSeverity.toStringAsFixed(1),
              hint: 'Scale 1–5',
            ),
            _StatTile(
              label: 'Nighttime',
              value: '${(stats.nighttimeRate * 100).round()}%',
              hint: 'of episodes',
            ),
            _StatTile(
              label: 'ER / urgent',
              value: '${(stats.erRate * 100).round()}%',
              hint: 'of episodes',
            ),
            _StatTile(
              label: 'Days between',
              value: stats.avgDaysBetween == null
                  ? '—'
                  : stats.avgDaysBetween!.toStringAsFixed(1),
              hint: 'average gap',
            ),
            _StatTile(
              label: 'Trend',
              value: switch (stats.trend) {
                Trend.improving => 'Improving',
                Trend.worsening => 'Worsening',
                Trend.stable => 'Stable',
                Trend.unknown => 'Unknown',
              },
              hint: 'vs prior window',
            ),
          ],
        ),
        const SizedBox(height: 16),
        BtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Episodes by week'),
              SizedBox(
                height: 180,
                child: stats.weeklyCounts.every((e) => e == 0)
                    ? const Center(
                        child: Text(
                          'No episodes in this window.',
                          style: TextStyle(color: BtColors.muted),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (stats.weeklyCounts.reduce((a, b) => a > b ? a : b) + 1)
                                  .toDouble(),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= stats.weeklyCounts.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    'W${i + 1}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            for (var i = 0; i < stats.weeklyCounts.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: stats.weeklyCounts[i].toDouble(),
                                    color: BtColors.sage,
                                    width: 14,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Triggers correlated with episodes'),
              if (stats.topTriggers.isEmpty)
                const Text(
                  'Tag triggers when you log episodes to see this chart.',
                  style: TextStyle(color: BtColors.muted),
                )
              else
                for (final e in stats.topTriggers.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(e.key.label, style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: e.value /
                                (stats.topTriggers.first.value.clamp(1, 99)),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: BtColors.sage,
                            backgroundColor: BtColors.sand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value}'),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Check-ins & peak flow'),
              Text(
                '${stats.checkInCount} check-ins · avg ${stats.avgRescuePuffs.toStringAsFixed(1)} rescue puffs/day logged',
              ),
              const SizedBox(height: 6),
              Text(
                'Yellow-zone PEF days: ${stats.yellowZoneDays} · red-zone: ${stats.redZoneDays}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Proposed improvements'),
        if (suggestions.isEmpty)
          const Text(
            'Log a bit more and suggestions will appear. They stay educational.',
            style: TextStyle(color: BtColors.muted),
          )
        else
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SuggestionCard(s),
            ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final text = visitSummaryText(
              child: child,
              stats: stats,
              episodes: ctrl.data.episodes,
            );
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visit summary copied')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy visit summary'),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.hint,
  });
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: BtCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: BtColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BtColors.ink,
              ),
            ),
            Text(hint, style: const TextStyle(fontSize: 11, color: BtColors.muted)),
          ],
        ),
      ),
    );
  }
}
