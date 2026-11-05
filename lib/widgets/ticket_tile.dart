import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/utils/formatters.dart';
import 'package:ticketing_app/widgets/badges.dart';

/// Ticket summary card used in lists.
class TicketTile extends StatelessWidget {
  const TicketTile({super.key, required this.ticket, this.showMenu = true});

  final Ticket ticket;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final done = !ticket.status.isActive;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(Routes.ticket(ticket.id)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: done ? scheme.outlineVariant : ticket.priority.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.reference,
                            style: muted?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                          ),
                          const SizedBox(width: 8),
                          Icon(ticket.category.icon, size: 13, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(child: Text(ticket.category.label, style: muted, overflow: TextOverflow.ellipsis)),
                          const Spacer(),
                          Text(Fmt.timeAgo(ticket.updatedAt), style: muted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: ticket.status == TicketStatus.closed ? TextDecoration.lineThrough : null,
                          color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ticket.clientName.isEmpty ? ticket.description : '${ticket.clientName} · ${ticket.description}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(ticket.status, dense: true),
                                PriorityBadge(ticket.priority, dense: true),
                                if (ticket.dueDate != null) DueBadge(ticket),
                              ],
                            ),
                          ),
                          if (ticket.comments.isNotEmpty) ...[
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('${ticket.comments.length}', style: muted),
                            const SizedBox(width: 10),
                          ],
                          Tooltip(
                            message: ticket.isUnassigned ? 'Unassigned' : ticket.assignee,
                            child: PersonAvatar(ticket.assignee, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (showMenu) _QuickMenu(ticket: ticket) else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TicketController>();
    return Align(
      alignment: Alignment.topCenter,
      child: PopupMenuButton<String>(
        tooltip: 'Quick actions',
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onSelected: (value) {
          if (value == 'edit') {
            Get.toNamed(Routes.editTicket(ticket.id));
          } else if (value == 'delete') {
            c.delete(ticket.id);
          } else if (value.startsWith('status:')) {
            c.setStatus(ticket.id, TicketStatus.fromName(value.substring(7)));
          }
        },
        itemBuilder: (context) => [
          for (final s in TicketStatus.values)
            if (s != ticket.status)
              PopupMenuItem(
                value: 'status:${s.name}',
                child: Row(children: [
                  Icon(s.icon, size: 18, color: s.color),
                  const SizedBox(width: 10),
                  Text('Mark as ${s.label.toLowerCase()}'),
                ]),
              ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ]),
          ),
        ],
      ),
    );
  }
}
