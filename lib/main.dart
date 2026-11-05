import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/settings_controller.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/pages/not_found_page.dart';
import 'package:ticketing_app/pages/shell_page.dart';
import 'package:ticketing_app/pages/ticket_detail_page.dart';
import 'package:ticketing_app/pages/ticket_form_page.dart';
import 'package:ticketing_app/routes.dart';
import 'package:ticketing_app/services/storage_service.dart';
import 'package:ticketing_app/utils/app_theme.dart';
import 'package:ticketing_app/utils/notify.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  runApp(const TicketDeskApp());
}

/// Registers storage and controllers. Exposed so tests can reuse it.
Future<void> initServices() async {
  await Get.putAsync(() => StorageService().init(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(TicketController(), permanent: true);
}

class TicketDeskApp extends StatelessWidget {
  const TicketDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return GetMaterialApp(
      title: 'TicketDesk',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode.value,
      defaultTransition: Transition.cupertino,
      initialRoute: Routes.home,
      getPages: [
        GetPage(name: Routes.home, page: () => const ShellPage()),
        GetPage(name: Routes.newTicket, page: () => const TicketFormPage()),
        GetPage(name: '/ticket/:id', page: () => const TicketDetailPage()),
        GetPage(name: '/ticket/:id/edit', page: () => TicketFormPage(ticketId: Get.parameters['id'])),
      ],
      unknownRoute: GetPage(name: '/not-found', page: () => const NotFoundPage()),
    );
  }
}
