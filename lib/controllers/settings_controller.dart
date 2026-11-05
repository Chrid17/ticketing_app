import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/services/storage_service.dart';

class SettingsController extends GetxController {
  final _storage = Get.find<StorageService>();

  final themeMode = ThemeMode.system.obs;

  /// Name of the support agent using the app — used for comments and the audit trail.
  final agentName = 'Support Agent'.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = ThemeMode.values.firstWhere((m) => m.name == _storage.themeMode, orElse: () => ThemeMode.system);
    final name = _storage.agentName;
    if (name != null && name.trim().isNotEmpty) agentName.value = name;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _storage.setThemeMode(mode.name);
  }

  void setAgentName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    agentName.value = clean;
    _storage.setAgentName(clean);
  }
}
