import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ticketing_app/controllers/settings_controller.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/pages/shell_page.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/utils/formatters.dart';
import 'package:ticketing_app/widgets/badges.dart';
import 'package:ticketing_app/widgets/common.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TicketController>();
    final settings = Get.find<SettingsController>();
    final nav = Get.find<NavController>();
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-fab',
        onPressed: () => Get.toNamed(Routes.newTicket),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New ticket'),
      ),
      body: SafeArea(
        child: Obx(() {
          final hasTickets = c.tickets.isNotEmpty;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageBody(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${_greeting()}, ${settings.agentName.value.split(' ').first}',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          hasTickets
                              ? _summaryLine(c)
                              : 'Your support desk is ready. Create your first ticket to get started.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!hasTickets)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No tickets yet',
                    message:
                        'Log client issues, track their progress and keep a full history of every conversation — all in one place.',
                    actions: [
                      FilledButton.icon(
                        onPressed: () => Get.toNamed(Routes.newTicket),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create ticket'),
                      ),
                      OutlinedButton.icon(
                        onPressed: c.loadDemoData,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Load demo tickets'),
                      ),
                    ],
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: PageBody(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      child: LayoutBuilder(builder: (context, box) {
                        final wide = box.maxWidth >= 900;
                        final statCols = box.maxWidth >= 900 ? 4 : 2;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StatGrid(columns: statCols, children: [
                              _StatCard(
                                label: 'Active tickets',
                                value: '${c.activeCount}',
                                icon: Icons.inbox_rounded,
                                color: const Color(0xFF4338CA),
                                caption: '${c.unassignedCount} unassigned',
                                onTap: () => nav.openTickets(TicketView.active),
                              ),
                              _StatCard(
                                label: 'Urgent',
                                value: '${c.urgentCount}',
                                icon: Icons.local_fire_department_outlined,
                                color: TicketPriority.urgent.color,
                                caption: 'Active, urgent priority',
                                onTap: () {
                                  nav.openTickets(TicketView.active);
                                  c.priorityFilter.add(TicketPriority.urgent);
                                },
                              ),
                              _StatCard(
                                label: 'Overdue',
                                value: '${c.overdueCount}',
                                icon: Icons.alarm_rounded,
                                color: const Color(0xFFD97706),
                                caption: 'Past their due date',
                                onTap: () => nav.openTickets(TicketView.overdue),
                              ),
                              _StatCard(
                                label: 'Resolved · 7 days',
                                value: '${c.resolvedThisWeek}',
                                icon: Icons.task_alt_rounded,
                                color: const Color(0xFF16A34A),
                                caption: c.averageResolution == null
                                    ? 'No resolutions yet'
                                    : 'Avg. ${Fmt.duration(c.averageResolution!)} to resolve',
                                onTap: () => nav.openTickets(TicketView.resolved),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _TwoColumn(
                              wide: wide,
                              flexLeft: 3,
                              left: _ActivityChart(data: c.last7Days),
                              right: _PriorityBreakdown(data: c.activePriorityBreakdown, total: c.activeCount),
                            ),
                            const SizedBox(height: 16),
                            _TwoColumn(
                              wide: wide,
                              flexLeft: 3,
                              left: _TicketListCard(
                                title: 'Needs attention',
                                subtitle: 'Overdue, due soon or high priority',
                                tickets: c.needsAttention,
                                emptyText: 'Nothing urgent — nice work.',
                                onSeeAll: () {
                                  nav.openTickets(TicketView.active);
                                  c.sort.value = TicketSort.priorityHigh;
                                },
                              ),
                              right: _StatusBreakdown(data: c.statusBreakdown, total: c.tickets.length),
                            ),
                            const SizedBox(height: 16),
                            _TwoColumn(
                              wide: wide,
                              flexLeft: 3,
                              left: _TicketListCard(
                                title: 'Recently updated',
                                subtitle: 'Latest activity across all tickets',
                                tickets: c.recentlyUpdated,
                                emptyText: 'No recent activity.',
                                onSeeAll: () {
                                  nav.openTickets(TicketView.all);
                                  c.sort.value = TicketSort.updated;
                                },
                              ),
                              right: _CategoryBreakdown(data: c.categoryBreakdown, total: c.tickets.length),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  String _summaryLine(TicketController c) {
    final parts = <String>['${c.activeCount} active ticket${c.activeCount == 1 ? '' : 's'}'];
    if (c.overdueCount > 0) parts.add('${c.overdueCount} overdue');
    if (c.unassignedCount > 0) parts.add('${c.unassignedCount} waiting for an owner');
    return '${parts.join(' · ')}.';
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.wide, required this.left, required this.right, this.flexLeft = 1});
  final bool wide;
  final Widget left;
  final Widget right;
  final int flexLeft;

  @override
  Widget build(BuildContext context) {
    if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 16), right]);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: flexLeft, child: left),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: right),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, i + columns > children.length ? children.length : i + columns);
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < slice.length; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(child: slice[j]),
            ],
          ],
        ),
      ));
      if (i + columns < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, size: 18, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(caption,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.data});
  final List<({DateTime day, int created, int resolved})> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const createdColor = Color(0xFF6366F1);
    const resolvedColor = Color(0xFF22C55E);
    final maxValue = data.fold<int>(1, (m, d) => [m, d.created, d.resolved].reduce((a, b) => a > b ? a : b));
    final totalCreated = data.fold<int>(0, (s, d) => s + d.created);
    final totalResolved = data.fold<int>(0, (s, d) => s + d.resolved);

    Widget legend(Color color, String label, int value) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('$label ($value)', style: theme.textTheme.bodySmall),
        ]);

    return SectionCard(
      title: 'Ticket volume',
      subtitle: 'Created vs resolved, last 7 days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 16, children: [
            legend(createdColor, 'Created', totalCreated),
            legend(resolvedColor, 'Resolved', totalResolved),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in data)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Bar(value: d.created, max: maxValue, color: createdColor),
                              const SizedBox(width: 4),
                              _Bar(value: d.resolved, max: maxValue, color: resolvedColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E').format(d.day),
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.max, required this.color});
  final int value;
  final int max;
  final Color color;

  /// Tallest bar in logical pixels (chart area minus labels).
  static const _maxBarHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    final h = value == 0 ? 3.0 : _maxBarHeight * value / max + 2;
    return Tooltip(
      message: '$value',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0) Text('$value', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: 12,
            height: h,
            decoration: BoxDecoration(
              color: value == 0 ? color.withValues(alpha: 0.18) : color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value, required this.total, required this.color, this.icon});
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 6)],
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text('$value', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(
                width: 44,
                child: Text(
                  '${(fraction * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBreakdown extends StatelessWidget {
  const _PriorityBreakdown({required this.data, required this.total});
  final Map<TicketPriority, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Active by priority',
      subtitle: '$total open item${total == 1 ? '' : 's'} in the queue',
      child: Column(
        children: [
          for (final e in data.entries)
            _BreakdownRow(label: e.key.label, value: e.value, total: total, color: e.key.color, icon: e.key.icon),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.data, required this.total});
  final Map<TicketStatus, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();
    final theme = Theme.of(context);
    final views = {
      TicketStatus.open: TicketView.open,
      TicketStatus.inProgress: TicketView.inProgress,
      TicketStatus.onHold: TicketView.onHold,
      TicketStatus.resolved: TicketView.resolved,
      TicketStatus.closed: TicketView.closed,
    };
    return SectionCard(
      title: 'Status overview',
      subtitle: '$total ticket${total == 1 ? '' : 's'} in total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final e in data.entries)
                    if (e.value > 0) Expanded(flex: e.value, child: Container(color: e.key.color)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final e in data.entries)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => nav.openTickets(views[e.key]!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(e.key.icon, size: 17, color: e.key.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key.label, style: theme.textTheme.bodyMedium)),
                    Text('${e.value}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.data, required this.total});
  final Map<TicketCategory, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SectionCard(
      title: 'By category',
      subtitle: 'Where requests are coming from',
      child: Column(
        children: [
          for (final e in data.entries)
            _BreakdownRow(label: e.key.label, value: e.value, total: total, color: color, icon: e.key.icon),
        ],
      ),
    );
  }
}

class _TicketListCard extends StatelessWidget {
  const _TicketListCard({
    required this.title,
    required this.subtitle,
    required this.tickets,
    required this.emptyText,
    required this.onSeeAll,
  });

  final String title;
  final String subtitle;
  final List<Ticket> tickets;
  final String emptyText;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      trailing: TextButton(onPressed: onSeeAll, child: const Text('View all')),
      child: tickets.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(emptyText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < tickets.length; i++) ...[
                  if (i > 0) const Divider(),
                  _CompactTicketRow(ticket: tickets[i]),
                ],
              ],
            ),
    );
  }
}

class _CompactTicketRow extends StatelessWidget {
  const _CompactTicketRow({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Get.toNamed(Routes.ticket(ticket.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: ticket.priority.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${ticket.reference} · ${ticket.clientName.isEmpty ? ticket.category.label : ticket.clientName} · ${Fmt.timeAgo(ticket.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (ticket.isOverdue || ticket.isDueSoon) ...[DueBadge(ticket), const SizedBox(width: 6)],
            StatusBadge(ticket.status, dense: true),
          ],
        ),
      ),
    );
  }
}
