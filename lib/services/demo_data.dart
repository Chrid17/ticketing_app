import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/utils/formatters.dart';

/// Sample tickets so the app can be explored without typing data in first.
/// Loaded only when the user taps "Load demo tickets".
List<Ticket> buildDemoTickets({required int startNumber, required String agent}) {
  final now = DateTime.now();
  DateTime ago({int d = 0, int h = 0, int m = 0}) => now.subtract(Duration(days: d, hours: h, minutes: m));
  DateTime ahead({int d = 0, int h = 0}) => now.add(Duration(days: d, hours: h));

  var n = startNumber;
  Ticket make({
    required String title,
    required String description,
    required TicketPriority priority,
    required TicketStatus status,
    required TicketCategory category,
    required String client,
    required String email,
    required DateTime created,
    String assignee = '',
    DateTime? due,
    DateTime? resolved,
    List<String> tags = const [],
    List<(String, String, bool, DateTime)> comments = const [],
  }) {
    final activity = <TicketActivity>[
      TicketActivity(message: 'Created ticket', actor: client, createdAt: created),
      if (assignee.isNotEmpty)
        TicketActivity(message: 'Assigned to $assignee', actor: agent, createdAt: created.add(const Duration(minutes: 12))),
      if (status != TicketStatus.open)
        TicketActivity(
          message: 'Changed status from Open to ${status.label}',
          actor: assignee.isNotEmpty ? assignee : agent,
          createdAt: resolved ?? created.add(const Duration(hours: 2)),
        ),
    ];
    final last = [created, ...activity.map((a) => a.createdAt), ...comments.map((c) => c.$4)]
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return Ticket(
      id: generateId() + (n).toString(),
      number: n++,
      title: title,
      description: description,
      priority: priority,
      status: status,
      category: category,
      clientName: client,
      clientEmail: email,
      assignee: assignee,
      dueDate: due,
      createdAt: created,
      updatedAt: last,
      resolvedAt: resolved,
      tags: tags,
      comments: [
        for (final c in comments)
          TicketComment(id: generateId(), author: c.$1, message: c.$2, isInternal: c.$3, createdAt: c.$4),
      ],
      activity: activity,
    );
  }

  return [
    make(
      title: 'Cannot log in after password reset',
      description:
          'I reset my password this morning but the portal keeps saying "invalid credentials". I have tried three times and now my account seems to be locked.',
      priority: TicketPriority.urgent,
      status: TicketStatus.inProgress,
      category: TicketCategory.account,
      client: 'Maria Shikongo',
      email: 'maria.shikongo@example.com',
      created: ago(h: 5),
      assignee: agent,
      due: ahead(h: 3),
      tags: ['login', 'lockout'],
      comments: [
        (agent, 'Hi Maria, thanks for reporting this. We can see the account was locked after 3 failed attempts. Unlocking it now.', false, ago(h: 4)),
        (agent, 'Reset token was generated twice — the first link was invalidated. Check with dev team.', true, ago(h: 3, m: 40)),
      ],
    ),
    make(
      title: 'Invoice #INV-2291 charged twice',
      description: 'Our card was charged twice for the October invoice. Please refund the duplicate payment.',
      priority: TicketPriority.high,
      status: TicketStatus.open,
      category: TicketCategory.billing,
      client: 'Johannes Nghipandulwa',
      email: 'accounts@example.org',
      created: ago(d: 1, h: 3),
      due: ago(h: 2),
      tags: ['refund'],
    ),
    make(
      title: 'Export to Excel produces empty file',
      description: 'When exporting the monthly sales report to .xlsx the downloaded file opens with no rows. CSV export works fine.',
      priority: TicketPriority.high,
      status: TicketStatus.inProgress,
      category: TicketCategory.bug,
      client: 'Anna Hamutenya',
      email: 'anna.h@example.com',
      created: ago(d: 2, h: 6),
      assignee: 'Peter Amukoto',
      due: ahead(d: 1),
      tags: ['reports', 'export'],
      comments: [
        ('Peter Amukoto', 'Reproduced on Chrome and Edge. Looks like the date filter is applied twice.', true, ago(d: 1, h: 20)),
      ],
    ),
    make(
      title: 'Request: dark mode for the client portal',
      description: 'Several of our staff work night shifts and would appreciate a dark theme in the portal.',
      priority: TicketPriority.low,
      status: TicketStatus.onHold,
      category: TicketCategory.featureRequest,
      client: 'Daniel Iipumbu',
      email: 'daniel@example.net',
      created: ago(d: 9),
      assignee: 'Lina Kaulinge',
      tags: ['ui', 'roadmap'],
    ),
    make(
      title: 'Printer not detected on reception PC',
      description: 'The HP LaserJet at reception stopped printing after the Windows update yesterday.',
      priority: TicketPriority.medium,
      status: TicketStatus.resolved,
      category: TicketCategory.technical,
      client: 'Selma Nangolo',
      email: 'selma.n@example.com',
      created: ago(d: 3, h: 2),
      assignee: agent,
      resolved: ago(d: 2, h: 20),
      tags: ['hardware'],
      comments: [
        (agent, 'Reinstalled the printer driver remotely and printed a test page. Please confirm it works on your side.', false, ago(d: 2, h: 21)),
        ('Selma Nangolo', 'Working perfectly now, thank you!', false, ago(d: 2, h: 20)),
      ],
    ),
    make(
      title: 'How do I add a new user to our account?',
      description: 'We hired a new accountant and need to give her access with view-only permissions.',
      priority: TicketPriority.low,
      status: TicketStatus.closed,
      category: TicketCategory.general,
      client: 'Thomas Shilongo',
      email: 'thomas@example.com',
      created: ago(d: 6),
      assignee: 'Lina Kaulinge',
      resolved: ago(d: 5, h: 22),
    ),
    make(
      title: 'Mobile app crashes when uploading photos',
      description: 'On Android 14 the app closes immediately after selecting a photo from the gallery to attach to a report.',
      priority: TicketPriority.urgent,
      status: TicketStatus.open,
      category: TicketCategory.bug,
      client: 'Ndapewa Haufiku',
      email: 'ndapewa@example.org',
      created: ago(h: 1, m: 20),
      due: ahead(h: 8),
      tags: ['android', 'crash'],
    ),
    make(
      title: 'Update billing address for VAT invoices',
      description: 'Please change our billing address to Unit 4, Independence Avenue. Future invoices need the new address.',
      priority: TicketPriority.medium,
      status: TicketStatus.resolved,
      category: TicketCategory.billing,
      client: 'Kauna Petrus',
      email: 'finance@example.net',
      created: ago(d: 4),
      assignee: 'Peter Amukoto',
      resolved: ago(d: 3, h: 18),
    ),
    make(
      title: 'Slow dashboard loading in the afternoons',
      description: 'Between 14:00 and 16:00 the dashboard takes more than 30 seconds to load.',
      priority: TicketPriority.medium,
      status: TicketStatus.open,
      category: TicketCategory.technical,
      client: 'Elago Mwandingi',
      email: 'elago@example.com',
      created: ago(d: 1, h: 1),
      due: ahead(d: 2),
      tags: ['performance'],
    ),
    make(
      title: 'Two-factor authentication codes not arriving',
      description: 'SMS codes for 2FA take over 10 minutes to arrive or never arrive at all.',
      priority: TicketPriority.high,
      status: TicketStatus.resolved,
      category: TicketCategory.account,
      client: 'Rauha Nekongo',
      email: 'rauha@example.org',
      created: ago(d: 1, h: 9),
      assignee: agent,
      resolved: ago(h: 6),
      tags: ['2fa', 'sms'],
      comments: [
        (agent, 'Our SMS provider had a delay on their side. It has been fixed — please try again.', false, ago(h: 7)),
      ],
    ),
  ];
}
