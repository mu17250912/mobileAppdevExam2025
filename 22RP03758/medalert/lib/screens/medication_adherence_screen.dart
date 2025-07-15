import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationAdherenceScreen extends StatefulWidget {
  const MedicationAdherenceScreen({super.key});

  @override
  State<MedicationAdherenceScreen> createState() => _MedicationAdherenceScreenState();
}

class _MedicationAdherenceScreenState extends State<MedicationAdherenceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    debugPrint('MedicationAdherenceScreen initialized');
    debugPrint('Current user: ${_auth.currentUser?.uid}');
    _checkAndCreateSampleLogs();
  }

  Future<void> _checkAndCreateSampleLogs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if there are any existing logs
      final logsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (logsSnapshot.docs.isEmpty) {
        debugPrint('No medication logs found, creating sample log...');
        
        // Create a sample medication log
        await _firestore.collection('medication_logs').add({
          'patientId': user.uid,
          'medicationId': 'sample_medication',
          'takenAt': FieldValue.serverTimestamp(),
          'status': 'taken',
        });
        
        debugPrint('Sample medication log created');
      } else {
        debugPrint('Found ${logsSnapshot.docs.length} existing medication logs');
      }
    } catch (e) {
      debugPrint('Error checking/creating sample logs: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Adherence"),
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
                        Icons.analytics,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Medication Adherence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your medication compliance',
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
                            Expanded(child: _buildStatCard('Today', '0/0', Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('This Week', '0/0', Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('This Month', '0/0', Colors.orange)),
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
                        child: _auth.currentUser == null
                            ? const Center(
                                child: Text(
                                  'Please log in to view medication logs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('medication_logs')
                                    .where('patientId', isEqualTo: _auth.currentUser!.uid)
                                    .limit(50)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  try {
                                    if (snapshot.hasError) {
                                      debugPrint('Error in medication logs stream: ${snapshot.error}');
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              size: 64,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Error loading medication logs',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        ),
                                      );
                                    }

                                    final logs = snapshot.data?.docs ?? [];
                                    
                                    // Sort logs by takenAt in descending order (most recent first)
                                    logs.sort((a, b) {
                                      final aData = a.data() as Map<String, dynamic>;
                                      final bData = b.data() as Map<String, dynamic>;
                                      final aTime = aData['takenAt'] as Timestamp?;
                                      final bTime = bData['takenAt'] as Timestamp?;
                                      
                                      if (aTime == null && bTime == null) return 0;
                                      if (aTime == null) return 1;
                                      if (bTime == null) return -1;
                                      
                                      return bTime.compareTo(aTime); // Descending order
                                    });

                                    if (logs.isEmpty) {
                                      return Center(
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
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Your medication adherence will appear here',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: logs.length,
                                      itemBuilder: (context, index) {
                                        final log = logs[index].data() as Map<String, dynamic>;
                                        return _buildLogCard(log, logs[index].id);
                                      },
                                    );
                                  } catch (e) {
                                    debugPrint('Exception in medication logs builder: $e');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            size: 64,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Error loading medication logs',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Exception: $e',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
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

  Widget _buildLogCard(Map<String, dynamic> log, String logId) {
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