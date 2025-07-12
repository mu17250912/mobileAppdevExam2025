import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bmi_entry.dart';

class BMIHistoryService {
  static const String _key = 'bmi_history';

  Future<void> addEntry(BMIEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    history.insert(0, jsonEncode(entry.toJson()));
    await prefs.setStringList(_key, history);
  }

  Future<List<BMIEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    return history
        .map((e) => BMIEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
} 