import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/utils/formatters.dart';
import 'package:ticketing_app/widgets/badges.dart';
import 'package:ticketing_app/widgets/common.dart';

/// Create a new ticket, or edit an existing one when [ticketId] is given.
class TicketFormPage extends StatefulWidget {
  const TicketFormPage({super.key, this.ticketId});
  final String? ticketId;

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final c = Get.find<TicketController>();
  final _formKey = GlobalKey<FormState>();

  late final Ticket? _original = widget.ticketId == null ? null : c.byId(widget.ticketId!);
  bool get _isEdit => _original != null;

  late final _title = TextEditingController(text: _original?.title ?? '');
  late final _description = TextEditingController(text: _original?.description ?? '');
  late final _clientName = TextEditingController(text: _original?.clientName ?? '');
  late final _clientEmail = TextEditingController(text: _original?.clientEmail ?? '');
  late final _assignee = TextEditingController(text: _original?.assignee ?? '');
  final _tagInput = TextEditingController();

  late TicketPriority _priority = _original?.priority ?? TicketPriority.medium;
  late TicketCategory _category = _original?.category ?? TicketCategory.general;
  late TicketStatus _status = _original?.status ?? TicketStatus.open;
  late DateTime? _dueDate = _original?.dueDate;
  late final List<String> _tags = [...?_original?.tags];

  bool _dirty = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    for (final ctrl in [_title, _description, _clientName, _clientEmail, _assignee]) {
      ctrl.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final ctrl in [_title, _description, _clientName, _clientEmail, _assignee, _tagInput]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: 'Select due date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : const TimeOfDay(hour: 17, minute: 0),
      helpText: 'Select due time',
    );
    if (!mounted) return;
    final t = time ?? const TimeOfDay(hour: 17, minute: 0);
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, t.hour, t.minute);
      _dirty = true;
    });
  }

  void _addTagsFrom(String raw) {
    final parts = raw
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim().replaceAll('#', '').toLowerCase())
        .where((t) => t.isNotEmpty && !_tags.contains(t));
    if (parts.isEmpty) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.addAll(parts.toSet());
      _dirty = true;
    });
    _tagInput.clear();
  }

  void _save() {
    setState(() => _submitted = true);
    if (_tagInput.text.trim().isNotEmpty) _addTagsFrom(_tagInput.text);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isEdit) {
      final o = _original!;
      final edited = o.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
        clientName: _clientName.text.trim(),
        clientEmail: _clientEmail.text.trim(),
        assignee: _assignee.text.trim(),
        priority: _priority,
        category: _category,
        status: _status,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        tags: List.of(_tags),
      );
      c.saveEdits(o, edited);
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
    } else {
      final t = c.create(
        title: _title.text,
        description: _description.text,
        priority: _priority,
        category: _category,
        clientName: _clientName.text,
        clientEmail: _clientEmail.text,
        assignee: _assignee.text,
        dueDate: _dueDate,
        tags: List.of(_tags),
      );
      setState(() => _dirty = false);
      // Replace the form with the new ticket's page.
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.offNamed(Routes.ticket(t.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.ticketId != null && _original == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Ticket not found',
          message: 'The ticket you are trying to edit no longer exists.',
          actions: [FilledButton(onPressed: () => Get.offAllNamed(Routes.home), child: const Text('Go to dashboard'))],
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirmDialog(
          context,
          title: 'Discard changes?',
          message: 'You have unsaved changes. If you leave now they will be lost.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (leave && mounted) {
          setState(() => _dirty = false);
          _close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop().then((popped) {
              if (!popped && !_dirty) Get.offAllNamed(Routes.home);
            }),
          ),
          title: Text(_isEdit ? 'Edit ${_original!.reference}' : 'New ticket'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(onPressed: _save, child: Text(_isEdit ? 'Save changes' : 'Create ticket')),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              PageBody(
                maxWidth: 820,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: 'Client',
                      subtitle: 'Who reported the issue',
                      child: LayoutBuilder(builder: (context, box) {
                        final name = TextFormField(
                          controller: _clientName,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Client name *',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the client\'s name' : null,
                        );
                        final email = TextFormField(
                          controller: _clientEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            return emailRegex.hasMatch(s) ? null : 'Enter a valid email address';
                          },
                        );
                        if (box.maxWidth < 560) {
                          return Column(children: [name, const SizedBox(height: 12), email]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Expanded(child: name), const SizedBox(width: 12), Expanded(child: email)],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Issue',
                      subtitle: 'Describe the problem clearly so anyone on the team can pick it up',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            maxLength: 120,
                            decoration: const InputDecoration(labelText: 'Subject *', hintText: 'e.g. Cannot log in after password reset'),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Enter a subject';
                              if (s.length < 5) return 'Subject should be at least 5 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _description,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 4,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              alignLabelWithHint: true,
                              hintText: 'What happened, steps to reproduce, what the client expected…',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Add a short description' : null,
                          ),
                          const SizedBox(height: 18),
                          Text('Category', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final cat in TicketCategory.values)
                              ChoiceChip(
                                avatar: Icon(cat.icon, size: 16),
                                label: Text(cat.label),
                                showCheckmark: false,
                                selected: _category == cat,
                                onSelected: (_) => setState(() {
                                  _category = cat;
                                  _dirty = true;
                                }),
                              ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Triage',
                      subtitle: 'Priority, ownership and deadline',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Priority', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final p in TicketPriority.values)
                              ChoiceChip(
                                avatar: Icon(p.icon, size: 16, color: p.color),
                                label: Text(p.label),
                                showCheckmark: false,
                                selected: _priority == p,
                                selectedColor: p.color.withValues(alpha: 0.16),
                                onSelected: (_) => setState(() {
                                  _priority = p;
                                  _dirty = true;
                                }),
                              ),
                          ]),
                          if (_isEdit) ...[
                            const SizedBox(height: 18),
                            Text('Status', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final s in TicketStatus.values)
                                ChoiceChip(
                                  avatar: Icon(s.icon, size: 16, color: s.color),
                                  label: Text(s.label),
                                  showCheckmark: false,
                                  selected: _status == s,
                                  selectedColor: s.color.withValues(alpha: 0.16),
                                  onSelected: (_) => setState(() {
                                    _status = s;
                                    _dirty = true;
                                  }),
                                ),
                            ]),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _assignee,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Assignee',
                              hintText: 'Leave empty to keep unassigned',
                              prefixIcon: Icon(Icons.support_agent_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final name in c.knownAssignees)
                              ActionChip(
                                avatar: PersonAvatar(name, size: 20),
                                label: Text(name),
                                onPressed: () => _assignee.text = name,
                              ),
                          ]),
                          const SizedBox(height: 18),
                          Text('Due date', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            OutlinedButton.icon(
                              onPressed: _pickDueDate,
                              icon: const Icon(Icons.event_outlined, size: 18),
                              label: Text(_dueDate == null ? 'Set due date' : Fmt.dateTime(_dueDate!)),
                            ),
                            for (final quick in const [(label: 'Today 17:00', days: 0), (label: 'Tomorrow', days: 1), (label: 'In 3 days', days: 3), (label: 'Next week', days: 7)])
                              ActionChip(
                                label: Text(quick.label),
                                onPressed: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _dueDate = DateTime(now.year, now.month, now.day + quick.days, 17);
                                    _dirty = true;
                                  });
                                },
                              ),
                            if (_dueDate != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _dueDate = null;
                                  _dirty = true;
                                }),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Remove'),
                              ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Tags',
                      subtitle: 'Optional keywords to make tickets easier to find',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _tagInput,
                            decoration: InputDecoration(
                              hintText: 'Type a tag and press Enter (e.g. login, refund)',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Add tag',
                                icon: const Icon(Icons.add_rounded),
                                onPressed: () => _addTagsFrom(_tagInput.text),
                              ),
                            ),
                            onSubmitted: _addTagsFrom,
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              for (final tag in _tags)
                                InputChip(
                                  label: Text('#$tag'),
                                  onDeleted: () => setState(() {
                                    _tags.remove(tag);
                                    _dirty = true;
                                  }),
                                ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: Icon(_isEdit ? Icons.save_outlined : Icons.add_rounded),
                          label: Text(_isEdit ? 'Save changes' : 'Create ticket'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
