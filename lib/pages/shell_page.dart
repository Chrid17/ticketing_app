import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/pages/dashboard_page.dart';
import 'package:ticketing_app/pages/settings_page.dart';
import 'package:ticketing_app/pages/tickets_page.dart';

/// Holds the selected top-level section so other screens can switch tabs.
class NavController extends GetxController {
  final index = 0.obs;

  void go(int i) => index.value = i;

  /// Jump to the tickets tab with a given quick view pre-selected.
  void openTickets(TicketView view) {
    final c = Get.find<TicketController>();
    c.clearFilters();
    c.view.value = view;
    index.value = 1;
  }
}

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  static const _destinations = [
    (icon: Icons.space_dashboard_outlined, selected: Icons.space_dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.confirmation_number_outlined, selected: Icons.confirmation_number_rounded, label: 'Tickets'),
    (icon: Icons.settings_outlined, selected: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavController(), permanent: true);
    final tickets = Get.find<TicketController>();
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 840;
    final extended = width >= 1200;
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final i = nav.index.value;
      final body = IndexedStack(
        index: i,
        children: const [DashboardPage(), TicketsPage(), SettingsPage()],
      );
      final activeCount = tickets.activeCount;

      Widget iconFor(int idx, bool selected) {
        final d = _destinations[idx];
        final icon = Icon(selected ? d.selected : d.icon);
        if (idx == 1 && activeCount > 0) {
          return Badge(label: Text('$activeCount'), child: icon);
        }
        return icon;
      }

      if (useRail) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extended,
                minExtendedWidth: 220,
                selectedIndex: i,
                onDestinationSelected: nav.go,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                  child: _Brand(extended: extended),
                ),
                destinations: [
                  for (var idx = 0; idx < _destinations.length; idx++)
                    NavigationRailDestination(
                      icon: iconFor(idx, false),
                      selectedIcon: iconFor(idx, true),
                      label: Text(_destinations[idx].label),
                    ),
                ],
              ),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              Expanded(child: body),
            ],
          ),
        );
      }

      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: nav.go,
          destinations: [
            for (var idx = 0; idx < _destinations.length; idx++)
              NavigationDestination(
                icon: iconFor(idx, false),
                selectedIcon: iconFor(idx, true),
                label: _destinations[idx].label,
              ),
          ],
        ),
      );
    });
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 22),
    );
    if (!extended) return logo;
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TicketDesk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('Client support',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
