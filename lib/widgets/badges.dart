import 'package:flutter/material.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/utils/formatters.dart';

Color _tint(BuildContext context, Color c) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return c.withValues(alpha: dark ? 0.22 : 0.10);
}

Color _fg(BuildContext context, Color c) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? Color.lerp(c, Colors.white, 0.35)! : c;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon, this.dense = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = _fg(context, color);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(color: _tint(context, color), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: dense ? 11 : 12, fontWeight: FontWeight.w600, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.dense = false});
  final TicketStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      _Pill(label: status.label, color: status.color, icon: status.icon, dense: dense);
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge(this.priority, {super.key, this.dense = false});
  final TicketPriority priority;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      _Pill(label: priority.label, color: priority.color, icon: priority.icon, dense: dense);
}

class TagBadge extends StatelessWidget {
  const TagBadge(this.tag, {super.key});
  final String tag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('#$tag', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
    );
  }
}

/// Due date indicator that turns amber when due soon and red when overdue.
class DueBadge extends StatelessWidget {
  const DueBadge(this.ticket, {super.key});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final due = ticket.dueDate;
    if (due == null) return const SizedBox.shrink();
    if (ticket.isOverdue) {
      return _Pill(label: 'Overdue ${Fmt.relative(due)}', color: const Color(0xFFDC2626), icon: Icons.schedule_rounded, dense: true);
    }
    if (ticket.isDueSoon) {
      return _Pill(label: 'Due in ${Fmt.relative(due)}', color: const Color(0xFFD97706), icon: Icons.schedule_rounded, dense: true);
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          ticket.status.isActive ? 'Due ${Fmt.shortDate(due)}' : Fmt.shortDate(due),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.size = 32});
  final String name;
  final double size;

  static const _palette = [
    Color(0xFF4338CA),
    Color(0xFF0E7490),
    Color(0xFF7C3AED),
    Color(0xFFBE185D),
    Color(0xFF15803D),
    Color(0xFFB45309),
    Color(0xFF1D4ED8),
  ];

  @override
  Widget build(BuildContext context) {
    if (name.trim().isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        child: Icon(Icons.person_outline_rounded, size: size * 0.55, color: scheme.onSurfaceVariant),
      );
    }
    final color = _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        Fmt.initials(name),
        style: TextStyle(color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w700),
      ),
    );
  }
}
