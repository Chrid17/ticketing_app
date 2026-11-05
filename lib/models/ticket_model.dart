import 'package:flutter/material.dart';

/// Ticket urgency. `weight` is used for sorting (higher = more urgent).
enum TicketPriority {
  low('Low', 1, Color(0xFF64748B), Icons.keyboard_double_arrow_down_rounded),
  medium('Medium', 2, Color(0xFF2563EB), Icons.drag_handle_rounded),
  high('High', 3, Color(0xFFEA580C), Icons.keyboard_arrow_up_rounded),
  urgent('Urgent', 4, Color(0xFFDC2626), Icons.priority_high_rounded);

  const TicketPriority(this.label, this.weight, this.color, this.icon);
  final String label;
  final int weight;
  final Color color;
  final IconData icon;

  static TicketPriority fromName(String? name) =>
      TicketPriority.values.firstWhere((p) => p.name == name, orElse: () => TicketPriority.medium);
}

/// Lifecycle of a ticket.
enum TicketStatus {
  open('Open', Color(0xFF2563EB), Icons.radio_button_unchecked_rounded),
  inProgress('In progress', Color(0xFF7C3AED), Icons.timelapse_rounded),
  onHold('On hold', Color(0xFFD97706), Icons.pause_circle_outline_rounded),
  resolved('Resolved', Color(0xFF16A34A), Icons.check_circle_outline_rounded),
  closed('Closed', Color(0xFF64748B), Icons.lock_outline_rounded);

  const TicketStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  /// Active tickets still need work from the support team.
  bool get isActive => this == open || this == inProgress || this == onHold;

  static TicketStatus fromName(String? name) =>
      TicketStatus.values.firstWhere((s) => s.name == name, orElse: () => TicketStatus.open);
}

enum TicketCategory {
  general('General', Icons.help_outline_rounded),
  technical('Technical', Icons.build_outlined),
  bug('Bug report', Icons.bug_report_outlined),
  billing('Billing', Icons.receipt_long_outlined),
  account('Account', Icons.person_outline_rounded),
  featureRequest('Feature request', Icons.lightbulb_outline_rounded);

  const TicketCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  static TicketCategory fromName(String? name) =>
      TicketCategory.values.firstWhere((c) => c.name == name, orElse: () => TicketCategory.general);
}

class TicketComment {
  final String id;
  final String author;
  final String message;
  final DateTime createdAt;

  /// Internal notes are only meant for the support team.
  final bool isInternal;

  const TicketComment({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
    this.isInternal = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'isInternal': isInternal,
      };

  factory TicketComment.fromJson(Map<String, dynamic> json) => TicketComment(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Unknown',
        message: json['message'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isInternal: json['isInternal'] as bool? ?? false,
      );
}

/// An audit-trail entry recorded automatically whenever a ticket changes.
class TicketActivity {
  final String message;
  final String actor;
  final DateTime createdAt;

  const TicketActivity({required this.message, required this.actor, required this.createdAt});

  Map<String, dynamic> toJson() => {'message': message, 'actor': actor, 'createdAt': createdAt.toIso8601String()};

  factory TicketActivity.fromJson(Map<String, dynamic> json) => TicketActivity(
        message: json['message'] as String? ?? '',
        actor: json['actor'] as String? ?? 'System',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class Ticket {
  final String id;
  final int number;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final TicketCategory category;
  final String clientName;
  final String clientEmail;
  final String assignee;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<String> tags;
  final List<TicketComment> comments;
  final List<TicketActivity> activity;

  const Ticket({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.clientName,
    required this.clientEmail,
    required this.assignee,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.resolvedAt,
    this.tags = const [],
    this.comments = const [],
    this.activity = const [],
  });

  /// Human-friendly reference, e.g. TCK-0042.
  String get reference => 'TCK-${number.toString().padLeft(4, '0')}';

  bool get isOverdue => dueDate != null && status.isActive && DateTime.now().isAfter(dueDate!);

  bool get isDueSoon {
    if (dueDate == null || !status.isActive || isOverdue) return false;
    return dueDate!.difference(DateTime.now()).inHours <= 24;
  }

  bool get isUnassigned => assignee.trim().isEmpty;

  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Time from creation until resolution (null while still active).
  Duration? get resolutionTime => resolvedAt?.difference(createdAt);

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return reference.toLowerCase().contains(q) ||
        title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        clientName.toLowerCase().contains(q) ||
        clientEmail.toLowerCase().contains(q) ||
        assignee.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }

  Ticket copyWith({
    String? title,
    String? description,
    TicketPriority? priority,
    TicketStatus? status,
    TicketCategory? category,
    String? clientName,
    String? clientEmail,
    String? assignee,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
    List<String>? tags,
    List<TicketComment>? comments,
    List<TicketActivity>? activity,
  }) {
    return Ticket(
      id: id,
      number: number,
      createdAt: createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      assignee: assignee ?? this.assignee,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      activity: activity ?? this.activity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'category': category.name,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'assignee': assignee,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'tags': tags,
        'comments': comments.map((c) => c.toJson()).toList(),
        'activity': activity.map((a) => a.toJson()).toList(),
      };

  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final created = parse(json['createdAt']) ?? DateTime.now();
    return Ticket(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: TicketPriority.fromName(json['priority'] as String?),
      status: TicketStatus.fromName(json['status'] as String?),
      category: TicketCategory.fromName(json['category'] as String?),
      clientName: json['clientName'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      assignee: json['assignee'] as String? ?? '',
      dueDate: parse(json['dueDate']),
      createdAt: created,
      updatedAt: parse(json['updatedAt']) ?? created,
      resolvedAt: parse(json['resolvedAt']),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      comments: (json['comments'] as List?)
              ?.map((e) => TicketComment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      activity: (json['activity'] as List?)
              ?.map((e) => TicketActivity.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
