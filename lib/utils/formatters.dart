import 'dart:math';

import 'package:intl/intl.dart';

final _random = Random();

/// Collision-resistant local id (time-based + random suffix).
String generateId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 30).toRadixString(36)}';

class Fmt {
  static final _date = DateFormat('d MMM yyyy');
  static final _dateTime = DateFormat('d MMM yyyy, HH:mm');
  static final _shortDate = DateFormat('d MMM');

  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String shortDate(DateTime d) => _shortDate.format(d);

  /// "just now", "5 min ago", "3 h ago", "2 days ago", or a date for older items.
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) return 'in ${relative(d)}';
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(d);
  }

  /// Distance to a future (or past) date, e.g. "2 days", "5 h".
  static String relative(DateTime d) {
    final diff = d.difference(DateTime.now()).abs();
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours >= 1) return '${diff.inHours} h';
    return '${max(1, diff.inMinutes)} min';
  }

  static String duration(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return '${d.inDays}d${h > 0 ? ' ${h}h' : ''}';
    }
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${max(1, d.inMinutes)}m';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');
