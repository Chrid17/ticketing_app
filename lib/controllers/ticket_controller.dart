import 'dart:convert';

import 'package:get/get.dart';
import 'package:ticketing_app/controllers/settings_controller.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/services/demo_data.dart';
import 'package:ticketing_app/services/storage_service.dart';
import 'package:ticketing_app/utils/formatters.dart';
import 'package:ticketing_app/utils/notify.dart';

/// Quick views shown as filter chips on the tickets screen.
enum TicketView {
  active('Active'),
  all('All'),
  mine('Assigned to me'),
  unassigned('Unassigned'),
  overdue('Overdue'),
  open('Open'),
  inProgress('In progress'),
  onHold('On hold'),
  resolved('Resolved'),
  closed('Closed');

  const TicketView(this.label);
  final String label;
}

enum TicketSort {
  updated('Recently updated'),
  newest('Newest first'),
  oldest('Oldest first'),
  priorityHigh('Priority: high → low'),
  priorityLow('Priority: low → high'),
  dueDate('Due date (soonest)');

  const TicketSort(this.label);
  final String label;
}

class TicketController extends GetxController {
  final _storage = Get.find<StorageService>();
  SettingsController get _settings => Get.find<SettingsController>();
  String get _me => _settings.agentName.value;

  final tickets = <Ticket>[].obs;

  // Filters
  final query = ''.obs;
  final view = TicketView.active.obs;
  final sort = TicketSort.updated.obs;
  final priorityFilter = <TicketPriority>{}.obs;
  final categoryFilter = Rxn<TicketCategory>();

  @override
  void onInit() {
    super.onInit();
    tickets.assignAll(_storage.loadTickets());
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Ticket? byId(String id) {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool get hasActiveFilters =>
      query.value.isNotEmpty || priorityFilter.isNotEmpty || categoryFilter.value != null;

  List<Ticket> get filtered {
    // Read every observable up-front so Obx always subscribes to all of them.
    final q = query.value.trim();
    final me = _me.toLowerCase();
    final currentView = view.value;
    final currentSort = sort.value;
    final priorities = priorityFilter.toSet();
    final category = categoryFilter.value;
    final list = tickets.where((t) {
      final inView = switch (currentView) {
        TicketView.all => true,
        TicketView.active => t.status.isActive,
        TicketView.mine => t.status.isActive && t.assignee.toLowerCase() == me,
        TicketView.unassigned => t.status.isActive && t.isUnassigned,
        TicketView.overdue => t.isOverdue,
        TicketView.open => t.status == TicketStatus.open,
        TicketView.inProgress => t.status == TicketStatus.inProgress,
        TicketView.onHold => t.status == TicketStatus.onHold,
        TicketView.resolved => t.status == TicketStatus.resolved,
        TicketView.closed => t.status == TicketStatus.closed,
      };
      if (!inView) return false;
      if (priorities.isNotEmpty && !priorities.contains(t.priority)) return false;
      if (category != null && t.category != category) return false;
      return t.matches(q);
    }).toList();

    list.sort((a, b) {
      switch (currentSort) {
        case TicketSort.updated:
          return b.updatedAt.compareTo(a.updatedAt);
        case TicketSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case TicketSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case TicketSort.priorityHigh:
          final c = b.priority.weight.compareTo(a.priority.weight);
          return c != 0 ? c : b.updatedAt.compareTo(a.updatedAt);
        case TicketSort.priorityLow:
          final c = a.priority.weight.compareTo(b.priority.weight);
          return c != 0 ? c : b.updatedAt.compareTo(a.updatedAt);
        case TicketSort.dueDate:
          if (a.dueDate == null && b.dueDate == null) return b.updatedAt.compareTo(a.updatedAt);
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    });
    return list;
  }

  int countFor(TicketView v) {
    final me = _me.toLowerCase();
    return tickets.where((t) {
      return switch (v) {
        TicketView.all => true,
        TicketView.active => t.status.isActive,
        TicketView.mine => t.status.isActive && t.assignee.toLowerCase() == me,
        TicketView.unassigned => t.status.isActive && t.isUnassigned,
        TicketView.overdue => t.isOverdue,
        TicketView.open => t.status == TicketStatus.open,
        TicketView.inProgress => t.status == TicketStatus.inProgress,
        TicketView.onHold => t.status == TicketStatus.onHold,
        TicketView.resolved => t.status == TicketStatus.resolved,
        TicketView.closed => t.status == TicketStatus.closed,
      };
    }).length;
  }

  void clearFilters() {
    query.value = '';
    priorityFilter.clear();
    categoryFilter.value = null;
  }

  void togglePriorityFilter(TicketPriority p) {
    if (priorityFilter.contains(p)) {
      priorityFilter.remove(p);
    } else {
      priorityFilter.add(p);
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard metrics
  // ---------------------------------------------------------------------------

  List<Ticket> get active => tickets.where((t) => t.status.isActive).toList();
  int get activeCount => active.length;
  int get overdueCount => tickets.where((t) => t.isOverdue).length;
  int get unassignedCount => active.where((t) => t.isUnassigned).length;
  int get urgentCount => active.where((t) => t.priority == TicketPriority.urgent).length;

  int get resolvedThisWeek {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return tickets.where((t) => t.resolvedAt != null && t.resolvedAt!.isAfter(since)).length;
  }

  Duration? get averageResolution {
    final times = tickets.map((t) => t.resolutionTime).whereType<Duration>().toList();
    if (times.isEmpty) return null;
    final total = times.fold<int>(0, (sum, d) => sum + d.inMinutes);
    return Duration(minutes: total ~/ times.length);
  }

  Map<TicketStatus, int> get statusBreakdown => {
        for (final s in TicketStatus.values) s: tickets.where((t) => t.status == s).length,
      };

  Map<TicketPriority, int> get activePriorityBreakdown => {
        for (final p in TicketPriority.values.reversed) p: active.where((t) => t.priority == p).length,
      };

  Map<TicketCategory, int> get categoryBreakdown {
    final map = {for (final c in TicketCategory.values) c: tickets.where((t) => t.category == c).length};
    final entries = map.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  /// Tickets created and resolved for each of the last 7 days (oldest first).
  List<({DateTime day, int created, int resolved})> get last7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return (
        day: day,
        created: tickets.where((t) => sameDay(t.createdAt, day)).length,
        resolved: tickets.where((t) => t.resolvedAt != null && sameDay(t.resolvedAt!, day)).length,
      );
    });
  }

  /// Active tickets that most need attention: overdue first, then by priority.
  List<Ticket> get needsAttention {
    final list = active.where((t) => t.isOverdue || t.isDueSoon || t.priority.weight >= 3).toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        final c = b.priority.weight.compareTo(a.priority.weight);
        if (c != 0) return c;
        return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
      });
    return list.take(5).toList();
  }

  List<Ticket> get recentlyUpdated => (tickets.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).take(5).toList();

  List<String> get knownAssignees {
    final names = tickets.map((t) => t.assignee.trim()).where((n) => n.isNotEmpty).toSet()..add(_me);
    return names.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  TicketActivity _log(String message) => TicketActivity(message: message, actor: _me, createdAt: DateTime.now());

  Future<void> _persist() => _storage.saveTickets(tickets);

  void _replace(Ticket t) {
    final i = tickets.indexWhere((x) => x.id == t.id);
    if (i >= 0) tickets[i] = t;
  }

  Ticket create({
    required String title,
    required String description,
    required TicketPriority priority,
    required TicketCategory category,
    required String clientName,
    required String clientEmail,
    String assignee = '',
    DateTime? dueDate,
    List<String> tags = const [],
  }) {
    final number = _storage.nextNumber;
    final now = DateTime.now();
    final ticket = Ticket(
      id: generateId(),
      number: number,
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      status: TicketStatus.open,
      category: category,
      clientName: clientName.trim(),
      clientEmail: clientEmail.trim(),
      assignee: assignee.trim(),
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      activity: [
        _log('Created ticket'),
        if (assignee.trim().isNotEmpty) _log('Assigned to ${assignee.trim()}'),
      ],
    );
    tickets.add(ticket);
    _storage.setNextNumber(number + 1);
    _persist();
    notify('${ticket.reference} created');
    return ticket;
  }

  /// Saves edits from the form and records a readable audit trail of what changed.
  void saveEdits(Ticket original, Ticket edited) {
    final changes = <String>[];
    if (original.title != edited.title) changes.add('Renamed ticket to "${edited.title}"');
    if (original.description != edited.description) changes.add('Updated the description');
    if (original.priority != edited.priority) {
      changes.add('Changed priority from ${original.priority.label} to ${edited.priority.label}');
    }
    if (original.category != edited.category) changes.add('Moved to ${edited.category.label}');
    if (original.status != edited.status) {
      changes.add('Changed status from ${original.status.label} to ${edited.status.label}');
    }
    if (original.assignee != edited.assignee) {
      changes.add(edited.assignee.isEmpty ? 'Removed assignee' : 'Assigned to ${edited.assignee}');
    }
    if (original.clientName != edited.clientName || original.clientEmail != edited.clientEmail) {
      changes.add('Updated client details');
    }
    if (original.dueDate != edited.dueDate) {
      changes.add(edited.dueDate == null ? 'Removed due date' : 'Set due date to ${Fmt.dateTime(edited.dueDate!)}');
    }
    if (original.tags.join(',') != edited.tags.join(',')) changes.add('Updated tags');
    if (changes.isEmpty) {
      notify('No changes to save');
      return;
    }
    var updated = _applyStatusTimestamps(original, edited);
    updated = updated.copyWith(updatedAt: DateTime.now(), activity: [...original.activity, ...changes.map(_log)]);
    _replace(updated);
    _persist();
    notify('${original.reference} updated');
  }

  Ticket _applyStatusTimestamps(Ticket before, Ticket after) {
    final wasDone = !before.status.isActive;
    final isDone = !after.status.isActive;
    if (!wasDone && isDone) return after.copyWith(resolvedAt: DateTime.now());
    if (wasDone && !isDone) return after.copyWith(clearResolvedAt: true);
    return after;
  }

  void setStatus(String id, TicketStatus status) {
    final t = byId(id);
    if (t == null || t.status == status) return;
    var updated = _applyStatusTimestamps(t, t.copyWith(status: status));
    updated = updated.copyWith(
      updatedAt: DateTime.now(),
      activity: [...t.activity, _log('Changed status from ${t.status.label} to ${status.label}')],
    );
    _replace(updated);
    _persist();
    notify('${t.reference} marked as ${status.label.toLowerCase()}');
  }

  void setPriority(String id, TicketPriority priority) {
    final t = byId(id);
    if (t == null || t.priority == priority) return;
    _replace(t.copyWith(
      priority: priority,
      updatedAt: DateTime.now(),
      activity: [...t.activity, _log('Changed priority from ${t.priority.label} to ${priority.label}')],
    ));
    _persist();
    notify('Priority set to ${priority.label}');
  }

  void assign(String id, String assignee) {
    final t = byId(id);
    final name = assignee.trim();
    if (t == null || t.assignee == name) return;
    _replace(t.copyWith(
      assignee: name,
      updatedAt: DateTime.now(),
      activity: [...t.activity, _log(name.isEmpty ? 'Removed assignee' : 'Assigned to $name')],
    ));
    _persist();
    notify(name.isEmpty ? 'Ticket unassigned' : 'Assigned to $name');
  }

  void addComment(String id, String message, {bool internal = false}) {
    final t = byId(id);
    final text = message.trim();
    if (t == null || text.isEmpty) return;
    final comment = TicketComment(
      id: generateId(),
      author: _me,
      message: text,
      createdAt: DateTime.now(),
      isInternal: internal,
    );
    _replace(t.copyWith(
      comments: [...t.comments, comment],
      updatedAt: DateTime.now(),
      activity: [...t.activity, _log(internal ? 'Added an internal note' : 'Replied to client')],
    ));
    _persist();
  }

  void deleteComment(String ticketId, String commentId) {
    final t = byId(ticketId);
    if (t == null) return;
    _replace(t.copyWith(comments: t.comments.where((c) => c.id != commentId).toList(), updatedAt: DateTime.now()));
    _persist();
    notify('Comment deleted');
  }

  void delete(String id) {
    final index = tickets.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final removed = tickets.removeAt(index);
    _persist();
    notify('${removed.reference} deleted', actionLabel: 'Undo', onAction: () {
      tickets.insert(index > tickets.length ? tickets.length : index, removed);
      _persist();
    });
  }

  // ---------------------------------------------------------------------------
  // Data management
  // ---------------------------------------------------------------------------

  void loadDemoData() {
    final start = _storage.nextNumber;
    final demo = buildDemoTickets(startNumber: start, agent: _me);
    tickets.addAll(demo);
    _storage.setNextNumber(start + demo.length);
    _storage.markSeeded();
    _persist();
    notify('${demo.length} demo tickets added');
  }

  Future<void> clearAll() async {
    tickets.clear();
    await _storage.clearTickets();
    notify('All tickets deleted');
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'TicketDesk',
        'exportedAt': DateTime.now().toIso8601String(),
        'tickets': tickets.map((t) => t.toJson()).toList(),
      });

  /// Imports tickets from a TicketDesk export. Existing tickets with the same id are replaced.
  int importJson(String raw) {
    final decoded = jsonDecode(raw);
    final List list = decoded is Map ? (decoded['tickets'] as List? ?? []) : decoded as List;
    final imported = list.map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    for (final t in imported) {
      final i = tickets.indexWhere((x) => x.id == t.id);
      if (i >= 0) {
        tickets[i] = t;
      } else {
        tickets.add(t);
      }
    }
    final maxNumber = tickets.fold<int>(0, (m, t) => t.number > m ? t.number : m);
    if (maxNumber >= _storage.nextNumber) _storage.setNextNumber(maxNumber + 1);
    _persist();
    return imported.length;
  }
}
