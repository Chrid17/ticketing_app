import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/widgets/common.dart';
import 'package:ticketing_app/widgets/ticket_tile.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final c = Get.find<TicketController>();
  late final TextEditingController _search = TextEditingController(text: c.query.value);
  Worker? _queryWorker;

  @override
  void initState() {
    super.initState();
    // Keep the search box in sync when filters are cleared from elsewhere (e.g. dashboard shortcuts).
    _queryWorker = ever<String>(c.query, (q) {
      if (_search.text != q) _search.text = q;
    });
  }

  @override
  void dispose() {
    _queryWorker?.dispose();
    _search.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tickets-fab',
        onPressed: () => Get.toNamed(Routes.newTicket),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New ticket'),
      ),
      body: SafeArea(
        child: PageBody(
          maxWidth: 1000,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Expanded(child: Text('Tickets', style: theme.textTheme.headlineSmall)),
                    Obx(() => PopupMenuButton<TicketSort>(
                          tooltip: 'Sort',
                          initialValue: c.sort.value,
                          onSelected: (s) => c.sort.value = s,
                          itemBuilder: (_) => [
                            for (final s in TicketSort.values)
                              CheckedPopupMenuItem(value: s, checked: s == c.sort.value, child: Text(s.label)),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.swap_vert_rounded, size: 20),
                              const SizedBox(width: 4),
                              Text(MediaQuery.sizeOf(context).width > 500 ? c.sort.value.label : 'Sort',
                                  style: theme.textTheme.labelLarge),
                            ]),
                          ),
                        )),
                    Obx(() {
                      final n = c.priorityFilter.length + (c.categoryFilter.value != null ? 1 : 0);
                      return IconButton(
                        tooltip: 'Filters',
                        onPressed: _openFilters,
                        icon: Badge(
                          isLabelVisible: n > 0,
                          label: Text('$n'),
                          child: const Icon(Icons.tune_rounded),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() => TextField(
                      controller: _search,
                      onChanged: (v) => c.query.value = v,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by title, client, reference, tag…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: c.query.value.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  c.query.value = '';
                                },
                              ),
                      ),
                    )),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: Obx(() {
                  final current = c.view.value;
                  c.tickets.length; // subscribe to list changes for counts
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (final v in TicketView.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${v.label}  ${c.countFor(v)}'),
                            selected: v == current,
                            showCheckmark: false,
                            onSelected: (_) => c.view.value = v,
                          ),
                        ),
                    ],
                  );
                }),
              ),
              Obx(() {
                if (c.priorityFilter.isEmpty && c.categoryFilter.value == null) return const SizedBox(height: 8);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final p in c.priorityFilter)
                        InputChip(
                          label: Text('Priority: ${p.label}'),
                          onDeleted: () => c.togglePriorityFilter(p),
                        ),
                      if (c.categoryFilter.value != null)
                        InputChip(
                          label: Text('Category: ${c.categoryFilter.value!.label}'),
                          onDeleted: () => c.categoryFilter.value = null,
                        ),
                      TextButton(
                        onPressed: () {
                          c.priorityFilter.clear();
                          c.categoryFilter.value = null;
                        },
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Expanded(
                child: Obx(() {
                  final list = c.filtered;
                  if (c.tickets.isEmpty) {
                    return EmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No tickets yet',
                      message: 'When a client reports an issue, log it here to track it through to resolution.',
                      actions: [
                        FilledButton.icon(
                          onPressed: () => Get.toNamed(Routes.newTicket),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create ticket'),
                        ),
                        OutlinedButton(onPressed: c.loadDemoData, child: const Text('Load demo tickets')),
                      ],
                    );
                  }
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No matching tickets',
                      message: 'Try a different search term, quick view or filter.',
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            c.clearFilters();
                            c.view.value = TicketView.all;
                          },
                          child: const Text('Show all tickets'),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 2 : 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Text(
                          '${list.length} ticket${list.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        );
                      }
                      final t = list[i - 1];
                      return TicketTile(key: ValueKey(t.id), ticket: t);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TicketController>();
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter tickets', style: theme.textTheme.titleLarge),
                const SizedBox(height: 18),
                Text('Priority', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in TicketPriority.values.reversed)
                    FilterChip(
                      avatar: Icon(p.icon, size: 16, color: p.color),
                      label: Text(p.label),
                      selected: c.priorityFilter.contains(p),
                      onSelected: (_) => c.togglePriorityFilter(p),
                    ),
                ]),
                const SizedBox(height: 18),
                Text('Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final cat in TicketCategory.values)
                    ChoiceChip(
                      avatar: Icon(cat.icon, size: 16),
                      label: Text(cat.label),
                      showCheckmark: false,
                      selected: c.categoryFilter.value == cat,
                      onSelected: (sel) => c.categoryFilter.value = sel ? cat : null,
                    ),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  TextButton(
                    onPressed: () {
                      c.priorityFilter.clear();
                      c.categoryFilter.value = null;
                    },
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Show results')),
                ]),
              ],
            )),
      ),
    );
  }
}
