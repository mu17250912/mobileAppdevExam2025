import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comprehensive analytics for a patient
  Future<Map<String, dynamic>> getPatientAnalytics(String patientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month - 1, 1);
      final end = endDate ?? now;

      // Get medication logs for the period (simplified query to avoid index issues)
      final logsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: patientId)
          .limit(100) // Limit to recent logs
          .get();

      final logs = logsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Get medications for the patient
      final medicationsSnapshot = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: patientId)
          .get();

      final medications = medicationsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return {
        'overallAdherence': _calculateOverallAdherence(logs),
        'dailyAdherence': _calculateDailyAdherence(logs, start, end),
        'weeklyAdherence': _calculateWeeklyAdherence(logs, start, end),
        'monthlyAdherence': _calculateMonthlyAdherence(logs, start, end),
        'medicationBreakdown': _calculateMedicationBreakdown(logs, medications),
        'missedDoses': _calculateMissedDoses(logs, start, end),
        'streakData': _calculateStreakData(logs),
        'timeOfDayAnalysis': _calculateTimeOfDayAnalysis(logs),
        'summary': _generateSummary(logs, medications, start, end),
      };
    } catch (e) {
      debugPrint('Error getting patient analytics: $e');
      return {};
    }
  }

  // Get caregiver analytics for all assigned patients
  Future<Map<String, dynamic>> getCaregiverAnalytics(String caregiverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month - 1, 1);
      final end = endDate ?? now;

      // Get assigned patients
      final patientsSnapshot = await _firestore
          .collection('users')
          .where('assignedCaregiverId', isEqualTo: caregiverId)
          .where('role', isEqualTo: 'patient')
          .get();

      final patients = patientsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Get analytics for each patient
      final patientAnalytics = <Map<String, dynamic>>[];
      double totalAdherence = 0;
      int totalPatients = patients.length;

      for (final patient in patients) {
        final analytics = await getPatientAnalytics(patient['id'], 
          startDate: start, endDate: end);
        
        patientAnalytics.add({
          'patient': patient,
          'analytics': analytics,
        });

        if (analytics['overallAdherence'] != null) {
          totalAdherence += analytics['overallAdherence'];
        }
      }

      final averageAdherence = totalPatients > 0 ? totalAdherence / totalPatients : 0;

      return {
        'patients': patientAnalytics,
        'averageAdherence': averageAdherence,
        'totalPatients': totalPatients,
        'summary': _generateCaregiverSummary(patientAnalytics, start, end),
      };
    } catch (e) {
      debugPrint('Error getting caregiver analytics: $e');
      return {};
    }
  }

  // Calculate overall adherence percentage
  double _calculateOverallAdherence(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;

    final takenCount = logs.where((log) => log['status'] == 'taken').length;
    return (takenCount / logs.length) * 100;
  }

  // Calculate daily adherence for chart data
  List<Map<String, dynamic>> _calculateDailyAdherence(
    List<Map<String, dynamic>> logs, 
    DateTime start, 
    DateTime end
  ) {
    final dailyData = <Map<String, dynamic>>[];
    final logsByDate = <String, List<Map<String, dynamic>>>{};

    // Group logs by date
    for (final log in logs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(takenAt.toDate());
        logsByDate.putIfAbsent(dateKey, () => []).add(log);
      }
    }

    // Calculate adherence for each day
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(current);
      final dayLogs = logsByDate[dateKey] ?? [];
      
      double adherence = 0;
      if (dayLogs.isNotEmpty) {
        final takenCount = dayLogs.where((log) => log['status'] == 'taken').length;
        adherence = (takenCount / dayLogs.length) * 100;
      }

      dailyData.add({
        'date': dateKey,
        'adherence': adherence,
        'totalDoses': dayLogs.length,
        'takenDoses': dayLogs.where((log) => log['status'] == 'taken').length,
        'missedDoses': dayLogs.where((log) => log['status'] != 'taken').length,
      });

      current = current.add(const Duration(days: 1));
    }

    return dailyData;
  }

  // Calculate weekly adherence
  List<Map<String, dynamic>> _calculateWeeklyAdherence(
    List<Map<String, dynamic>> logs, 
    DateTime start, 
    DateTime end
  ) {
    final weeklyData = <Map<String, dynamic>>[];
    final logsByWeek = <String, List<Map<String, dynamic>>>{};

    // Group logs by week
    for (final log in logs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final date = takenAt.toDate();
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);
        logsByWeek.putIfAbsent(weekKey, () => []).add(log);
      }
    }

    // Calculate adherence for each week
    DateTime current = start;
    while (current.isBefore(end)) {
      final weekStart = current.subtract(Duration(days: current.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);
      final weekLogs = logsByWeek[weekKey] ?? [];
      
      double adherence = 0;
      if (weekLogs.isNotEmpty) {
        final takenCount = weekLogs.where((log) => log['status'] == 'taken').length;
        adherence = (takenCount / weekLogs.length) * 100;
      }

      weeklyData.add({
        'week': weekKey,
        'adherence': adherence,
        'totalDoses': weekLogs.length,
        'takenDoses': weekLogs.where((log) => log['status'] == 'taken').length,
        'missedDoses': weekLogs.where((log) => log['status'] != 'taken').length,
      });

      current = current.add(const Duration(days: 7));
    }

    return weeklyData;
  }

  // Calculate monthly adherence
  List<Map<String, dynamic>> _calculateMonthlyAdherence(
    List<Map<String, dynamic>> logs, 
    DateTime start, 
    DateTime end
  ) {
    final monthlyData = <Map<String, dynamic>>[];
    final logsByMonth = <String, List<Map<String, dynamic>>>{};

    // Group logs by month
    for (final log in logs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final date = takenAt.toDate();
        final monthKey = DateFormat('yyyy-MM').format(date);
        logsByMonth.putIfAbsent(monthKey, () => []).add(log);
      }
    }

    // Calculate adherence for each month
    DateTime current = DateTime(start.year, start.month, 1);
    while (current.isBefore(end)) {
      final monthKey = DateFormat('yyyy-MM').format(current);
      final monthLogs = logsByMonth[monthKey] ?? [];
      
      double adherence = 0;
      if (monthLogs.isNotEmpty) {
        final takenCount = monthLogs.where((log) => log['status'] == 'taken').length;
        adherence = (takenCount / monthLogs.length) * 100;
      }

      monthlyData.add({
        'month': monthKey,
        'adherence': adherence,
        'totalDoses': monthLogs.length,
        'takenDoses': monthLogs.where((log) => log['status'] == 'taken').length,
        'missedDoses': monthLogs.where((log) => log['status'] != 'taken').length,
      });

      current = DateTime(current.year, current.month + 1, 1);
    }

    return monthlyData;
  }

  // Calculate medication breakdown
  List<Map<String, dynamic>> _calculateMedicationBreakdown(
    List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> medications
  ) {
    final medicationData = <Map<String, dynamic>>[];
    final logsByMedication = <String, List<Map<String, dynamic>>>{};

    // Group logs by medication
    for (final log in logs) {
      final medicationId = log['medicationId'] as String?;
      if (medicationId != null) {
        logsByMedication.putIfAbsent(medicationId, () => []).add(log);
      }
    }

    // Calculate adherence for each medication
    for (final medication in medications) {
      final medicationId = medication['id'] as String?;
      final logs = logsByMedication[medicationId] ?? [];
      
      double adherence = 0;
      if (logs.isNotEmpty) {
        final takenCount = logs.where((log) => log['status'] == 'taken').length;
        adherence = (takenCount / logs.length) * 100;
      }

      medicationData.add({
        'medication': medication,
        'adherence': adherence,
        'totalDoses': logs.length,
        'takenDoses': logs.where((log) => log['status'] == 'taken').length,
        'missedDoses': logs.where((log) => log['status'] != 'taken').length,
      });
    }

    return medicationData;
  }

  // Calculate missed doses analysis
  Map<String, dynamic> _calculateMissedDoses(
    List<Map<String, dynamic>> logs,
    DateTime start,
    DateTime end
  ) {
    final missedLogs = logs.where((log) => log['status'] != 'taken').toList();
    final missedByDay = <String, int>{};
    final missedByHour = <int, int>{};

    for (final log in missedLogs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final date = takenAt.toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final hour = date.hour;

        missedByDay[dateKey] = (missedByDay[dateKey] ?? 0) + 1;
        missedByHour[hour] = (missedByHour[hour] ?? 0) + 1;
      }
    }

    return {
      'totalMissed': missedLogs.length,
      'missedByDay': missedByDay,
      'missedByHour': missedByHour,
      'mostMissedHour': missedByHour.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
    };
  }

  // Calculate streak data
  Map<String, dynamic> _calculateStreakData(List<Map<String, dynamic>> logs) {
    final logsByDate = <String, List<Map<String, dynamic>>>{};

    // Group logs by date
    for (final log in logs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(takenAt.toDate());
        logsByDate.putIfAbsent(dateKey, () => []).add(log);
      }
    }

    final sortedDates = logsByDate.keys.toList()..sort();
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (final dateKey in sortedDates.reversed) {
      final logs = logsByDate[dateKey]!;
      final allTaken = logs.every((log) => log['status'] == 'taken');
      
      if (allTaken && logs.isNotEmpty) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        if (currentStreak == 0) {
          currentStreak = tempStreak;
        }
        tempStreak = 0;
      }
    }
    
    if (currentStreak == 0) {
      currentStreak = tempStreak;
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalDaysWithMedications': sortedDates.length,
    };
  }

  // Calculate time of day analysis
  Map<String, dynamic> _calculateTimeOfDayAnalysis(List<Map<String, dynamic>> logs) {
    final takenLogs = logs.where((log) => log['status'] == 'taken').toList();
    final timeDistribution = <int, int>{};

    for (final log in takenLogs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final hour = takenAt.toDate().hour;
        timeDistribution[hour] = (timeDistribution[hour] ?? 0) + 1;
      }
    }

    return {
      'timeDistribution': timeDistribution,
      'mostCommonHour': timeDistribution.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
    };
  }

  // Generate summary for patients
  Map<String, dynamic> _generateSummary(
    List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> medications,
    DateTime start,
    DateTime end
  ) {
    final totalDoses = logs.length;
    final takenDoses = logs.where((log) => log['status'] == 'taken').length;
    final missedDoses = totalDoses - takenDoses;
    final adherence = totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0;
    final daysInPeriod = end.difference(start).inDays + 1;

    return {
      'period': '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}',
      'totalDoses': totalDoses,
      'takenDoses': takenDoses,
      'missedDoses': missedDoses,
      'adherence': adherence,
      'medicationsCount': medications.length,
      'daysInPeriod': daysInPeriod,
      'averageDosesPerDay': totalDoses / daysInPeriod,
    };
  }

  // Generate summary for caregivers
  Map<String, dynamic> _generateCaregiverSummary(
    List<Map<String, dynamic>> patientAnalytics,
    DateTime start,
    DateTime end
  ) {
    int totalDoses = 0;
    int totalTaken = 0;
    int totalMissed = 0;

    for (final patientData in patientAnalytics) {
      final analytics = patientData['analytics'] as Map<String, dynamic>;
      final summary = analytics['summary'] as Map<String, dynamic>?;
      
      if (summary != null) {
        totalDoses += (summary['totalDoses'] ?? 0) as int;
        totalTaken += (summary['takenDoses'] ?? 0) as int;
        totalMissed += (summary['missedDoses'] ?? 0) as int;
      }
    }

    final adherence = totalDoses > 0 ? (totalTaken / totalDoses) * 100 : 0;

    return {
      'period': '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}',
      'totalPatients': patientAnalytics.length,
      'totalDoses': totalDoses,
      'totalTaken': totalTaken,
      'totalMissed': totalMissed,
      'overallAdherence': adherence,
    };
  }
} 