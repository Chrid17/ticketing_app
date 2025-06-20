import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/main_controller.dart';
import 'package:ticketing_app/pages/home_page.dart';
import 'package:ticketing_app/pages/shoprite_test_orders_page.dart';
import 'package:ticketing_app/utils/app_themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(MainController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(title: 'Client Ticket App', theme: AppThemes.appTheme, home: ShopriteTestOrdersPage());
  }
}
