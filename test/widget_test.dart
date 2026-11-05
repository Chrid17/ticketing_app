import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/models/ticket_model.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    await initServices();
  });

  group('TicketController', () {
    test('creates tickets with sequential references and an audit entry', () {
      final c = Get.find<TicketController>();
      final a = c.create(
        title: 'Printer offline',
        description: 'Reception printer not responding',
        priority: TicketPriority.high,
        category: TicketCategory.technical,
        clientName: 'Jane Doe',
        clientEmail: 'jane@example.com',
      );
      final b = c.create(
        title: 'Refund request',
        description: 'Charged twice',
        priority: TicketPriority.low,
        category: TicketCategory.billing,
        clientName: 'John Doe',
        clientEmail: '',
      );
      expect(a.reference, 'TCK-0001');
      expect(b.reference, 'TCK-0002');
      expect(a.status, TicketStatus.open);
      expect(a.activity.first.message, 'Created ticket');
      expect(c.activeCount, 2);
    });

    test('resolving sets resolvedAt and reopening clears it', () {
      final c = Get.find<TicketController>();
      final t = c.create(
        title: 'Login issue',
        description: 'Cannot sign in',
        priority: TicketPriority.urgent,
        category: TicketCategory.account,
        clientName: 'Client',
        clientEmail: '',
      );
      c.setStatus(t.id, TicketStatus.resolved);
      expect(c.byId(t.id)!.resolvedAt, isNotNull);
      expect(c.activeCount, 0);
      c.setStatus(t.id, TicketStatus.open);
      expect(c.byId(t.id)!.resolvedAt, isNull);
      expect(c.byId(t.id)!.activity.length, 3);
    });

    test('filters by view, priority and search query', () {
      final c = Get.find<TicketController>();
      c.loadDemoData();
      c.view.value = TicketView.all;
      expect(c.filtered.length, 10);

      c.priorityFilter.add(TicketPriority.urgent);
      expect(c.filtered.every((t) => t.priority == TicketPriority.urgent), isTrue);

      c.clearFilters();
      c.query.value = 'INV-2291';
      expect(c.filtered.length, 1);

      c.clearFilters();
      c.view.value = TicketView.overdue;
      expect(c.filtered.every((t) => t.isOverdue), isTrue);
    });

    test('sorts by priority high to low', () {
      final c = Get.find<TicketController>();
      c.loadDemoData();
      c.view.value = TicketView.all;
      c.sort.value = TicketSort.priorityHigh;
      final weights = c.filtered.map((t) => t.priority.weight).toList();
      final sorted = [...weights]..sort((a, b) => b.compareTo(a));
      expect(weights, sorted);
    });

    test('comments are stored and export/import round-trips', () {
      final c = Get.find<TicketController>();
      final t = c.create(
        title: 'Export broken',
        description: 'Empty file',
        priority: TicketPriority.medium,
        category: TicketCategory.bug,
        clientName: 'Client',
        clientEmail: '',
      );
      c.addComment(t.id, 'Looking into it', internal: true);
      final json = c.exportJson();
      c.tickets.clear();
      expect(c.importJson(json), 1);
      final restored = c.byId(t.id)!;
      expect(restored.comments.single.message, 'Looking into it');
      expect(restored.comments.single.isInternal, isTrue);
    });
  });

  testWidgets('app starts on an empty dashboard and can load demo data', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TicketDeskApp());
    await tester.pumpAndSettle();

    expect(find.text('No tickets yet'), findsOneWidget);
    await tester.tap(find.text('Load demo tickets'));
    await tester.pumpAndSettle();

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Ticket volume'), findsOneWidget);

    // Let the "demo tickets added" snackbar time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
