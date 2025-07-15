import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationCalendarScreen extends StatefulWidget {
  const MedicationCalendarScreen({super.key});

  @override
  State<MedicationCalendarScreen> createState() => _MedicationCalendarScreenState();
}

class _MedicationCalendarScreenState extends State<MedicationCalendarScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime _focusedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _medicationLogs = {};
  Map<String, double> _adherenceStats = {};

  @override
  void initState() {
    super.initState();
    _loadMedicationLogs();
  }

  Future<void> _loadMedicationLogs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get medication logs for the current month

      final logsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: user.uid)
          .get();

      final logs = logsSnapshot.docs;
      final logsByDate = <String, List<Map<String, dynamic>>>{};

      for (final doc in logs) {
        final log = doc.data();
        final takenAt = log['takenAt'] as Timestamp?;
        if (takenAt != null) {
          final logDate = takenAt.toDate();
          // Only include logs for the current month
          if (logDate.year == _focusedDate.year && logDate.month == _focusedDate.month) {
            final dateKey = DateFormat('yyyy-MM-dd').format(logDate);
            logsByDate.putIfAbsent(dateKey, () => []).add(log);
          }
        }
      }

      setState(() {
        _medicationLogs = logsByDate;
      });

      _calculateAdherenceStats();
    } catch (e) {
      debugPrint('Error loading medication logs: $e');
    }
  }

  void _calculateAdherenceStats() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Calculate adherence for different periods
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double todayAdherence = 0;
    double weekAdherence = 0;
    double monthAdherence = 0;

    // Today's adherence
    if (_medicationLogs.containsKey(today)) {
      final todayLogs = _medicationLogs[today]!;
      final takenCount = todayLogs.where((log) => log['status'] == 'taken').length;
      final totalCount = todayLogs.length;
      todayAdherence = totalCount > 0 ? (takenCount / totalCount) * 100 : 0;
    }

    // Week's adherence
    int weekTaken = 0;
    int weekTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (_medicationLogs.containsKey(dateKey)) {
        final logs = _medicationLogs[dateKey]!;
        weekTaken += logs.where((log) => log['status'] == 'taken').length;
        weekTotal += logs.length;
      }
    }
    weekAdherence = weekTotal > 0 ? (weekTaken / weekTotal) * 100 : 0;

    // Month's adherence
    int monthTaken = 0;
    int monthTotal = 0;
    for (final entry in _medicationLogs.entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      if (date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        final logs = entry.value;
        monthTaken += logs.where((log) => log['status'] == 'taken').length;
        monthTotal += logs.length;
      }
    }
    monthAdherence = monthTotal > 0 ? (monthTaken / monthTotal) * 100 : 0;

    setState(() {
      _adherenceStats = {
        'today': todayAdherence,
        'week': weekAdherence,
        'month': monthAdherence,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Calendar"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
              Color(0xFF90CAF9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medication Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your daily medication adherence',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Statistics Cards
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard('Today', '${_adherenceStats['today']?.toStringAsFixed(1) ?? '0'}%', Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('This Week', '${_adherenceStats['week']?.toStringAsFixed(1) ?? '0'}%', Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('This Month', '${_adherenceStats['month']?.toStringAsFixed(1) ?? '0'}%', Colors.orange)),
                          ],
                        ),
                      ),
                      
                      // Calendar
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Calendar Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                                      });
                                      _loadMedicationLogs();
                                    },
                                  ),
                                  Text(
                                    DateFormat('MMMM yyyy').format(_focusedDate),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                                      });
                                      _loadMedicationLogs();
                                    },
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Calendar Grid
                              Expanded(
                                child: _buildCalendarGrid(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        
        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              final day = dayOffset + 1;
              
              if (day < 1 || day > daysInMonth) {
                return Container(); // Empty space
              }
              
              final date = DateTime(_focusedDate.year, _focusedDate.month, day);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final isToday = date.isAtSameMomentAs(DateTime.now().toUtc().toLocal());
              final logs = _medicationLogs[dateKey] ?? [];
              
              return _buildCalendarDay(date, logs, isToday);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date, List<Map<String, dynamic>> logs, bool isToday) {
    final takenCount = logs.where((log) => log['status'] == 'taken').length;
    final totalCount = logs.length;
    
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    
    if (isToday) {
      borderColor = Colors.blue;
    }
    
    if (totalCount > 0) {
      if (takenCount == totalCount) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (takenCount > 0) {
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange;
      } else {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    }
    
    return GestureDetector(
      onTap: () => _showDayDetails(date, logs),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.blue : Colors.black87,
              ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$takenCount/$totalCount',
                style: TextStyle(
                  fontSize: 10,
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, List<Map<String, dynamic>> logs) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (logs.isEmpty)
              const Text('No medications scheduled for this day')
            else ...[
              Text(
                'Medications (${logs.where((log) => log['status'] == 'taken').length}/${logs.length} taken)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...logs.map((log) => _buildLogItem(log)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final status = log['status'] as String?;
    final takenAt = log['takenAt'] as Timestamp?;
    final medicationId = log['medicationId'] as String?;
    
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('medications').doc(medicationId).get(),
      builder: (context, snapshot) {
        String medicationName = 'Unknown Medication';
        if (snapshot.hasData && snapshot.data!.exists) {
          final medication = snapshot.data!.data() as Map<String, dynamic>;
          medicationName = medication['name'] ?? 'Unknown Medication';
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status == 'taken' ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: status == 'taken' ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                status == 'taken' ? Icons.check_circle : Icons.cancel,
                color: status == 'taken' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (takenAt != null)
                      Text(
                        'Taken at: ${DateFormat('HH:mm').format(takenAt.toDate())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'taken' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'taken' ? 'Taken' : 'Missed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 