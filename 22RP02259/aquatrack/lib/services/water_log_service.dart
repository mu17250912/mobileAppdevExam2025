import 'package:flutter/material.dart';
import '../models/water_log.dart';

class WaterLogService extends ChangeNotifier {
  final List<WaterLog> _logs = [];

  List<WaterLog> get allLogs => List.unmodifiable(_logs);

  List<WaterLog> get todaysLogs {
    final today = DateTime.now();
    return _logs.where((log) =>
      log.timestamp.year == today.year &&
      log.timestamp.month == today.month &&
      log.timestamp.day == today.day
    ).toList();
  }

  void addLog(WaterLog log) {
    _logs.add(log);
    notifyListeners();
  }
} 