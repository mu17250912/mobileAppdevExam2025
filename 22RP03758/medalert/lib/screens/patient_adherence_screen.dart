import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientAdherenceScreen extends StatefulWidget {
  final String patientId;

  const PatientAdherenceScreen({super.key, required this.patientId});

  @override
  State<PatientAdherenceScreen> createState() => _PatientAdherenceScreenState();
}

class _PatientAdherenceScreenState extends State<PatientAdherenceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _medicationLogs = [];
  Map<String, dynamic> _adherenceStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      // Load patient information
      final patientDoc = await _firestore.collection('users').doc(widget.patientId).get();
      if (patientDoc.exists) {
        _patientData = patientDoc.data();
      }

      // Load medication logs
      final logsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('takenAt', descending: true)
          .limit(100)
          .get();

      final logs = logsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _medicationLogs = logs;
        _isLoading = false;
      });

      _calculateAdherenceStats();
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateAdherenceStats() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double todayAdherence = 0;
    double weekAdherence = 0;
    double monthAdherence = 0;
    int currentStreak = 0;
    int longestStreak = 0;

    // Group logs by date
    final logsByDate = <String, List<Map<String, dynamic>>>{};
    for (final log in _medicationLogs) {
      final takenAt = log['takenAt'] as Timestamp?;
      if (takenAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(takenAt.toDate());
        logsByDate.putIfAbsent(dateKey, () => []).add(log);
      }
    }

    // Calculate today's adherence
    if (logsByDate.containsKey(today)) {
      final todayLogs = logsByDate[today]!;
      final takenCount = todayLogs.where((log) => log['status'] == 'taken').length;
      final totalCount = todayLogs.length;
      todayAdherence = totalCount > 0 ? (takenCount / totalCount) * 100 : 0;
    }

    // Calculate week's adherence
    int weekTaken = 0;
    int weekTotal = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (logsByDate.containsKey(dateKey)) {
        final logs = logsByDate[dateKey]!;
        weekTaken += logs.where((log) => log['status'] == 'taken').length;
        weekTotal += logs.length;
      }
    }
    weekAdherence = weekTotal > 0 ? (weekTaken / weekTotal) * 100 : 0;

    // Calculate month's adherence
    int monthTaken = 0;
    int monthTotal = 0;
    for (final entry in logsByDate.entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      if (date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        final logs = entry.value;
        monthTaken += logs.where((log) => log['status'] == 'taken').length;
        monthTotal += logs.length;
      }
    }
    monthAdherence = monthTotal > 0 ? (monthTaken / monthTotal) * 100 : 0;

    // Calculate streaks
    final sortedDates = logsByDate.keys.toList()..sort();
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

    setState(() {
      _adherenceStats = {
        'today': todayAdherence,
        'week': weekAdherence,
        'month': monthAdherence,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patientData?['name'] ?? 'Patient Adherence'),
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
                        Icons.person,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _patientData?['name'] ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _patientData?['email'] ?? '',
                      style: const TextStyle(
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Column(
                          children: [
                            // Statistics Cards
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatCard('Today', '${_adherenceStats['today']?.toStringAsFixed(1) ?? '0'}%', Colors.green)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildStatCard('This Week', '${_adherenceStats['week']?.toStringAsFixed(1) ?? '0'}%', Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatCard('This Month', '${_adherenceStats['month']?.toStringAsFixed(1) ?? '0'}%', Colors.orange)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildStatCard('Current Streak', '${_adherenceStats['currentStreak'] ?? 0} days', Colors.purple)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatCard('Longest Streak', '${_adherenceStats['longestStreak'] ?? 0} days', Colors.indigo),
                                ],
                              ),
                            ),
                            
                            // Medication Logs Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Recent Medication Logs',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Medication Logs
                            Expanded(
                              child: _medicationLogs.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.history,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'No medication logs yet',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _medicationLogs.length,
                                      itemBuilder: (context, index) {
                                        final log = _medicationLogs[index];
                                        return _buildLogCard(log);
                                      },
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

  Widget _buildLogCard(Map<String, dynamic> log) {
    final takenAt = log['takenAt'] as Timestamp?;
    final status = log['status'] as String?;
    final medicationId = log['medicationId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status == 'taken' ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status == 'taken' ? Icons.check_circle : Icons.cancel,
                color: status == 'taken' ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('medications').doc(medicationId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final medication = snapshot.data!.data() as Map<String, dynamic>;
                        return Text(
                          medication['name'] ?? 'Unknown Medication',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      }
                      return const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    takenAt != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(takenAt.toDate())
                        : 'Unknown time',
                    style: TextStyle(
                      fontSize: 14,
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
      ),
    );
  }
} 