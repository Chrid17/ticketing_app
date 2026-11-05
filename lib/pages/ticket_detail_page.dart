import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/settings_controller.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/utils/formatters.dart';
import 'package:ticketing_app/utils/notify.dart';
import 'package:ticketing_app/widgets/badges.dart';
import 'package:ticketing_app/widgets/common.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, this.ticketId});

  /// Optional explicit id; otherwise read from the route (`/ticket/:id`).
  final String? ticketId;

  void _goBack() {
    if (Navigator.of(Get.context!).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TicketController>();
    final id = ticketId ?? Get.parameters['id'] ?? '';

    return Obx(() {
      final t = c.byId(id);
      if (t == null) {
        return Scaffold(
          appBar: AppBar(leading: BackButton(onPressed: _goBack)),
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ticket not found',
            message: 'This ticket may have been deleted or the link is incorrect.',
            actions: [FilledButton(onPressed: () => Get.offAllNamed(Routes.home), child: const Text('Go to dashboard'))],
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _goBack),
          title: Text(t.reference),
          actions: [
            IconButton(
              tooltip: 'Copy reference',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${t.reference} — ${t.title}'));
                notify('Reference copied');
              },
            ),
            IconButton(
              tooltip: 'Edit ticket',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Get.toNamed(Routes.editTicket(t.id)),
            ),
            IconButton(
              tooltip: 'Delete ticket',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Delete ${t.reference}?',
                  message: 'The ticket, its conversation and history will be removed. You can undo right after.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (ok) {
                  final id = t.id;
                  _goBack();
                  // Delete after the page has animated away so it never flashes "not found".
                  Future.delayed(const Duration(milliseconds: 350), () => c.delete(id));
                }
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 980;
          final main = [
            _Header(ticket: t),
            const SizedBox(height: 16),
            _DescriptionCard(ticket: t),
            const SizedBox(height: 16),
            _Conversation(ticket: t),
          ];
          final side = [
            _PropertiesCard(ticket: t),
            const SizedBox(height: 16),
            _ActivityCard(ticket: t),
          ];
          if (wide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: PageBody(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: main)),
                    const SizedBox(width: 20),
                    SizedBox(width: 360, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: side)),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [main[0], const SizedBox(height: 16), side[0], const SizedBox(height: 16), ...main.skip(2), const SizedBox(height: 16), side[2]],
          );
        }),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = Get.find<TicketController>();
    final t = ticket;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            StatusBadge(t.status),
            PriorityBadge(t.priority),
            if (t.dueDate != null) DueBadge(t),
          ]),
          const SizedBox(height: 12),
          SelectableText(t.title, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            'Opened ${Fmt.timeAgo(t.createdAt)} by ${t.clientName.isEmpty ? 'unknown client' : t.clientName} · updated ${Fmt.timeAgo(t.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (t.status == TicketStatus.open)
              FilledButton.icon(
                onPressed: () => c.setStatus(t.id, TicketStatus.inProgress),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start work'),
              ),
            if (t.status == TicketStatus.open)
              OutlinedButton.icon(
                onPressed: () => c.setStatus(t.id, TicketStatus.resolved),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Resolve'),
              )
            else if (t.status.isActive)
              FilledButton.icon(
                onPressed: () => c.setStatus(t.id, TicketStatus.resolved),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Resolve'),
              ),
            if (t.status == TicketStatus.resolved)
              FilledButton.icon(
                onPressed: () => c.setStatus(t.id, TicketStatus.closed),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Close ticket'),
              ),
            if (!t.status.isActive)
              OutlinedButton.icon(
                onPressed: () => c.setStatus(t.id, TicketStatus.open),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Reopen'),
              ),
            if (t.status.isActive && t.isUnassigned)
              OutlinedButton.icon(
                onPressed: () => c.assign(t.id, Get.find<SettingsController>().agentName.value),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Assign to me'),
              ),
          ]),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            ticket.description.isEmpty ? 'No description provided.' : ticket.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          if (ticket.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in ticket.tags) TagBadge(tag)]),
          ],
        ],
      ),
    );
  }
}

class _PropertiesCard extends StatelessWidget {
  const _PropertiesCard({required this.ticket});
  final Ticket ticket;

  Future<void> _pickAssignee(BuildContext context) async {
    final c = Get.find<TicketController>();
    final input = TextEditingController(text: ticket.assignee);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign ticket'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: input,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Agent name', prefixIcon: Icon(Icons.person_outline_rounded)),
                onSubmitted: (v) => Navigator.of(ctx).pop(v),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final name in c.knownAssignees)
                  ActionChip(
                    avatar: PersonAvatar(name, size: 20),
                    label: Text(name),
                    onPressed: () => Navigator.of(ctx).pop(name),
                  ),
              ]),
            ],
          ),
        ),
        actions: [
          if (!ticket.isUnassigned) TextButton(onPressed: () => Navigator.of(ctx).pop(''), child: const Text('Unassign')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(input.text), child: const Text('Assign')),
        ],
      ),
    );
    input.dispose();
    if (result != null) c.assign(ticket.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TicketController>();
    final theme = Theme.of(context);
    final t = ticket;
    final value = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);

    return SectionCard(
      title: 'Details',
      child: Column(
        children: [
          PropertyRow(
            label: 'Status',
            icon: Icons.flag_outlined,
            child: PopupMenuButton<TicketStatus>(
              tooltip: 'Change status',
              initialValue: t.status,
              onSelected: (s) => c.setStatus(t.id, s),
              itemBuilder: (_) => [
                for (final s in TicketStatus.values)
                  PopupMenuItem(
                    value: s,
                    child: Row(children: [Icon(s.icon, size: 18, color: s.color), const SizedBox(width: 10), Text(s.label)]),
                  ),
              ],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                StatusBadge(t.status),
                const Icon(Icons.arrow_drop_down_rounded),
              ]),
            ),
          ),
          PropertyRow(
            label: 'Priority',
            icon: Icons.signal_cellular_alt_rounded,
            child: PopupMenuButton<TicketPriority>(
              tooltip: 'Change priority',
              initialValue: t.priority,
              onSelected: (p) => c.setPriority(t.id, p),
              itemBuilder: (_) => [
                for (final p in TicketPriority.values.reversed)
                  PopupMenuItem(
                    value: p,
                    child: Row(children: [Icon(p.icon, size: 18, color: p.color), const SizedBox(width: 10), Text(p.label)]),
                  ),
              ],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                PriorityBadge(t.priority),
                const Icon(Icons.arrow_drop_down_rounded),
              ]),
            ),
          ),
          PropertyRow(
            label: 'Assignee',
            icon: Icons.support_agent_rounded,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickAssignee(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  PersonAvatar(t.assignee, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.isUnassigned ? 'Unassigned' : t.assignee,
                      overflow: TextOverflow.ellipsis,
                      style: t.isUnassigned ? value?.copyWith(color: theme.colorScheme.onSurfaceVariant) : value,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded),
                ]),
              ),
            ),
          ),
          PropertyRow(
            label: 'Category',
            icon: Icons.folder_outlined,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.category.icon, size: 16),
              const SizedBox(width: 6),
              Text(t.category.label, style: value),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          PropertyRow(
            label: 'Client',
            icon: Icons.business_outlined,
            child: Text(t.clientName.isEmpty ? '—' : t.clientName, style: value, overflow: TextOverflow.ellipsis),
          ),
          PropertyRow(
            label: 'Email',
            icon: Icons.alternate_email_rounded,
            child: t.clientEmail.isEmpty
                ? Text('—', style: value)
                : InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: t.clientEmail));
                      notify('Email address copied');
                    },
                    child: Text(
                      t.clientEmail,
                      overflow: TextOverflow.ellipsis,
                      style: value?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          PropertyRow(label: 'Created', icon: Icons.add_circle_outline_rounded, child: Text(Fmt.dateTime(t.createdAt), style: value)),
          PropertyRow(label: 'Updated', icon: Icons.update_rounded, child: Text(Fmt.dateTime(t.updatedAt), style: value)),
          PropertyRow(
            label: 'Due',
            icon: Icons.event_outlined,
            child: Text(
              t.dueDate == null ? 'No due date' : Fmt.dateTime(t.dueDate!),
              style: t.isOverdue ? value?.copyWith(color: theme.colorScheme.error) : value,
            ),
          ),
          if (t.resolvedAt != null)
            PropertyRow(
              label: 'Resolved',
              icon: Icons.task_alt_rounded,
              child: Text('${Fmt.dateTime(t.resolvedAt!)}  (${Fmt.duration(t.resolutionTime!)})', style: value),
            ),
        ],
      ),
    );
  }
}

class _Conversation extends StatefulWidget {
  const _Conversation({required this.ticket});
  final Ticket ticket;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final _input = TextEditingController();
  bool _internal = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    Get.find<TicketController>().addComment(widget.ticket.id, text, internal: _internal);
    _input.clear();
    FocusScope.of(context).unfocus();
    notify(_internal ? 'Internal note added' : 'Reply added');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final comments = widget.ticket.comments;
    final c = Get.find<TicketController>();

    return SectionCard(
      title: 'Conversation',
      subtitle: comments.isEmpty ? 'No replies yet' : '${comments.length} message${comments.length == 1 ? '' : 's'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonAvatar(m.author, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
                      decoration: BoxDecoration(
                        color: m.isInternal ? const Color(0xFFF59E0B).withValues(alpha: 0.10) : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: m.isInternal ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : scheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(m.author,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                              ),
                              if (m.isInternal) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFFB45309)),
                                const SizedBox(width: 3),
                                const Text('Internal',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                              ],
                              const Spacer(),
                              Tooltip(
                                message: Fmt.dateTime(m.createdAt),
                                child: Text(Fmt.timeAgo(m.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                              ),
                              SizedBox(
                                width: 32,
                                height: 28,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  tooltip: 'Message options',
                                  onSelected: (v) {
                                    if (v == 'copy') {
                                      Clipboard.setData(ClipboardData(text: m.message));
                                      notify('Message copied');
                                    } else if (v == 'delete') {
                                      c.deleteComment(widget.ticket.id, m.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'copy', child: Text('Copy text')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SelectableText(m.message, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: _input,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _internal ? 'Write an internal note (only visible to your team)…' : 'Write a reply to the client…',
              fillColor: _internal ? const Color(0xFFF59E0B).withValues(alpha: 0.08) : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                avatar: Icon(Icons.lock_outline_rounded, size: 16, color: _internal ? const Color(0xFFB45309) : null),
                label: const Text('Internal note'),
                selected: _internal,
                showCheckmark: false,
                onSelected: (v) => setState(() => _internal = v),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: _input,
                builder: (context, _) => FilledButton.icon(
                  onPressed: _input.text.trim().isEmpty ? null : _send,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_internal ? 'Add note' : 'Send reply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.ticket});
  final Ticket ticket;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = widget.ticket.activity.reversed.toList();
    final visible = _showAll ? items : items.take(6).toList();

    return SectionCard(
      title: 'Activity',
      subtitle: 'Full audit trail of changes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 18,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: i == 0 ? scheme.primary : scheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < visible.length - 1)
                          Expanded(child: Container(width: 1.5, margin: const EdgeInsets.only(top: 4), color: scheme.outlineVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visible[i].message, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 2),
                          Text(
                            '${visible[i].actor} · ${Fmt.dateTime(visible[i].createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (items.length > 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? 'Show less' : 'Show all ${items.length} events'),
              ),
            ),
        ],
      ),
    );
  }
}
