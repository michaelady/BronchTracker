import 'package:bronchtracker/models/models.dart';
import 'package:bronchtracker/theme.dart';
import 'package:flutter/material.dart';

const medicalDisclaimer =
    'BronchTracker is a home diary, not a medical device and not emergency care. '
    'It does not diagnose, treat, or prescribe. If your child has severe breathing '
    'distress — cannot speak, lips or nails look blue, ribs pulling in, or you are '
    'worried — call emergency services (911 in the US) immediately.';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BtColors.coral.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: BtColors.coral,
            size: compact ? 18 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              compact
                  ? 'Not a medical device. Call emergency services for severe distress.'
                  : medicalDisclaimer,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.35,
                color: BtColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BtCard extends StatelessWidget {
  const BtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: BtColors.muted,
        ),
      ),
    );
  }
}

class ZoneChip extends StatelessWidget {
  const ZoneChip(this.zone, {super.key});
  final PefZone zone;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (zone) {
      PefZone.green => ('Green zone', BtColors.greenZone),
      PefZone.yellow => ('Yellow zone', BtColors.yellowZone),
      PefZone.red => ('Red zone', BtColors.redZone),
      PefZone.unknown => ('No PEF zone', BtColors.muted),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SeverityDots extends StatelessWidget {
  const SeverityDots(this.value, {super.key});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(
              Icons.circle,
              size: 10,
              color: i <= value
                  ? (value >= 4 ? BtColors.coral : BtColors.sage)
                  : BtColors.sand,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          '$value · ${severityLabel(value)}',
          style: const TextStyle(fontSize: 12, color: BtColors.muted),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: BtColors.sage),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BtColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BtColors.muted, height: 1.4),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBtMessage(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('BronchTracker'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}
