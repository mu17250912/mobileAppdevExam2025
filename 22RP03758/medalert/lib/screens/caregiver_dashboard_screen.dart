import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'patient_adherence_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedPatients();
  }

  Future<void> _loadAssignedPatients() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get patients assigned to this caregiver
      final patientsSnapshot = await _firestore
          .collection('users')
          .where('assignedCaregiverId', isEqualTo: user.uid)
          .where('role', isEqualTo: 'patient')
          .get();

      final patients = <Map<String, dynamic>>[];
      
      for (final doc in patientsSnapshot.docs) {
        final patientData = doc.data();
        patientData['id'] = doc.id;
        
        // Get patient's recent medication adherence
        final adherenceData = await _getPatientAdherence(doc.id);
        patientData.addAll(adherenceData);
        
        patients.add(patientData);
      }

      setState(() {
        _assignedPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading assigned patients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getPatientAdherence(String patientId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      // Get all logs for the patient
      final allLogsSnapshot = await _firestore
          .collection('medication_logs')
          .where('patientId', isEqualTo: patientId)
          .get();

      final allLogs = allLogsSnapshot.docs;
      
      // Filter today's logs
      final todayLogs = allLogs.where((doc) {
        final takenAt = doc.data()['takenAt'] as Timestamp?;
        if (takenAt == null) return false;
        final logDate = takenAt.toDate();
        return logDate.year == now.year && 
               logDate.month == now.month && 
               logDate.day == now.day;
      }).toList();
      
      final todayTaken = todayLogs.where((doc) => doc.data()['status'] == 'taken').length;
      final todayTotal = todayLogs.length;

      // Filter week's logs
      final weekLogs = allLogs.where((doc) {
        final takenAt = doc.data()['takenAt'] as Timestamp?;
        if (takenAt == null) return false;
        final logDate = takenAt.toDate();
        return logDate.isAfter(weekStart.subtract(const Duration(days: 1)));
      }).toList();
      
      final weekTaken = weekLogs.where((doc) => doc.data()['status'] == 'taken').length;
      final weekTotal = weekLogs.length;

      // Get missed medications today
      final missedToday = todayLogs.where((doc) => doc.data()['status'] != 'taken').length;

      return {
        'todayAdherence': todayTotal > 0 ? (todayTaken / todayTotal) * 100 : 0,
        'weekAdherence': weekTotal > 0 ? (weekTaken / weekTotal) * 100 : 0,
        'missedToday': missedToday,
        'totalToday': todayTotal,
        'takenToday': todayTaken,
      };
    } catch (e) {
      debugPrint('Error getting patient adherence: $e');
      return {
        'todayAdherence': 0,
        'weekAdherence': 0,
        'missedToday': 0,
        'totalToday': 0,
        'takenToday': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Caregiver Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Patient Profiles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/multi_user_profiles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility),
              title: const Text('Accessibility Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics & Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/caregiver_analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Personal Insights'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/insights');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Refer Friends'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/referral');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Premium Features'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
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
                        Icons.medical_services,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Caregiver Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Managing ${_assignedPatients.length} patients',
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
                      : _assignedPatients.isEmpty
                          ? _buildEmptyState()
                          : _buildPatientsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No patients assigned yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Patients will appear here once they assign themselves to you',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAssignmentInfo(),
            icon: const Icon(Icons.info),
            label: const Text('How to get patients'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.people,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Assigned Patients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAssignedPatients,
              ),
            ],
          ),
        ),
        
        // Patients List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _assignedPatients.length,
            itemBuilder: (context, index) {
              final patient = _assignedPatients[index];
              return _buildPatientCard(patient);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? 'Unknown Patient';
    final email = patient['email'] ?? '';
    final todayAdherence = patient['todayAdherence'] ?? 0.0;
    final weekAdherence = patient['weekAdherence'] ?? 0.0;
    final missedToday = patient['missedToday'] ?? 0;
    final totalToday = patient['totalToday'] ?? 0;
    final takenToday = patient['takenToday'] ?? 0;

    Color statusColor = Colors.green;
    String statusText = 'Good';
    
    if (missedToday > 0) {
      statusColor = Colors.orange;
      statusText = 'Missed $missedToday';
    }
    
    if (todayAdherence < 50) {
      statusColor = Colors.red;
      statusText = 'Poor';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Adherence Statistics
            Row(
              children: [
                Expanded(
                  child: _buildAdherenceStat(
                    'Today',
                    '${todayAdherence.toStringAsFixed(1)}%',
                    '$takenToday/$totalToday',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdherenceStat(
                    'This Week',
                    '${weekAdherence.toStringAsFixed(1)}%',
                    'Weekly',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPatientAdherence(patient),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendReminder(patient),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Send Reminder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceStat(String title, String percentage, String details, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            details,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPatientAdherence(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientAdherenceScreen(patientId: patient['id']),
      ),
    );
  }

  void _sendReminder(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Text('Send a reminder to ${patient['name']} about their medications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showReminderSent(patient['name']);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReminderSent(String patientName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder sent to $patientName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAssignmentInfo() {
    final userEmail = _auth.currentUser?.email ?? 'Unknown';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Get Patients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To have patients assigned to you:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1. Share your caregiver credentials with patients'),
            const Text('2. Patients will use your email/password to assign themselves'),
            const Text('3. They will appear in your dashboard once assigned'),
            const SizedBox(height: 12),
            const Text(
              'Your credentials:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: $userEmail'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
} 