import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketing_app/models/ticket_model.dart';

/// Local persistence (works on Android, iOS, web, Windows, macOS and Linux).
class StorageService extends GetxService {
  static const _ticketsKey = 'ticketdesk.tickets.v2';
  static const _nextNumberKey = 'ticketdesk.nextNumber';
  static const _themeKey = 'ticketdesk.themeMode';
  static const _agentKey = 'ticketdesk.agentName';
  static const _seededKey = 'ticketdesk.seeded';

  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  List<Ticket> loadTickets() {
    final raw = _prefs.getString(_ticketsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTickets(List<Ticket> tickets) =>
      _prefs.setString(_ticketsKey, jsonEncode(tickets.map((t) => t.toJson()).toList()));

  int get nextNumber => _prefs.getInt(_nextNumberKey) ?? 1;
  Future<void> setNextNumber(int value) => _prefs.setInt(_nextNumberKey, value);

  String? get themeMode => _prefs.getString(_themeKey);
  Future<void> setThemeMode(String value) => _prefs.setString(_themeKey, value);

  String? get agentName => _prefs.getString(_agentKey);
  Future<void> setAgentName(String value) => _prefs.setString(_agentKey, value);

  bool get hasSeeded => _prefs.getBool(_seededKey) ?? false;
  Future<void> markSeeded() => _prefs.setBool(_seededKey, true);

  Future<void> clearTickets() async {
    await _prefs.remove(_ticketsKey);
    await _prefs.remove(_nextNumberKey);
  }
}
