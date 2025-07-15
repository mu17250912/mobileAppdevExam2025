import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/offline_service.dart';

class MultiUserProfilesScreen extends StatefulWidget {
  const MultiUserProfilesScreen({super.key});

  @override
  State<MultiUserProfilesScreen> createState() => _MultiUserProfilesScreenState();
}

class _MultiUserProfilesScreenState extends State<MultiUserProfilesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineService _offlineService = OfflineService();
  
  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoading = true;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    _loadAssignedPatients();
  }

  Future<void> _loadAssignedPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get patients assigned to this caregiver using both methods for comprehensive coverage
      final patientsData = <Map<String, dynamic>>[];
      final processedPatientIds = <String>{};

      // Method 1: Get from caregiver_assignments collection
      final assignmentsSnapshot = await _firestore
          .collection('caregiver_assignments')
          .where('caregiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in assignmentsSnapshot.docs) {
        final patientId = doc.data()['patientId'] as String;
        if (!processedPatientIds.contains(patientId)) {
          processedPatientIds.add(patientId);
          await _loadPatientDetails(patientId, patientsData, doc.data());
        }
      }

      // Method 2: Get from users collection where assignedCaregiverId matches
      final usersSnapshot = await _firestore
          .collection('users')
          .where('assignedCaregiverId', isEqualTo: user.uid)
          .where('role', isEqualTo: 'patient')
          .get();

      for (final doc in usersSnapshot.docs) {
        final patientId = doc.id;
        if (!processedPatientIds.contains(patientId)) {
          processedPatientIds.add(patientId);
          await _loadPatientDetails(patientId, patientsData, {});
        }
      }

      setState(() {
        _assignedPatients = patientsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading patients: $e');
    }
  }

  Future<void> _loadPatientDetails(String patientId, List<Map<String, dynamic>> patientsData, Map<String, dynamic> assignmentData) async {
    try {
      final patientDoc = await _firestore
          .collection('users')
          .doc(patientId)
          .get();
      
      if (patientDoc.exists) {
        final patientData = patientDoc.data()!;
        
        // Get recent medication adherence data
        final adherenceSnapshot = await _firestore
            .collection('medication_logs')
            .where('patientId', isEqualTo: patientId)
            .limit(7)
            .get();

        final recentLogs = adherenceSnapshot.docs;
        final takenCount = recentLogs.where((doc) => doc.data()['status'] == 'taken').length;
        final adherencePercentage = recentLogs.isNotEmpty ? (takenCount / recentLogs.length * 100).round() : 0;

        // Get medication count
        final medicationsSnapshot = await _firestore
            .collection('medications')
            .where('patientId', isEqualTo: patientId)
            .get();

        final medicationCount = medicationsSnapshot.docs.length;

        patientsData.add({
          'id': patientId,
          'name': patientData['name'] ?? 'Unknown Patient',
          'email': patientData['email'] ?? '',
          'phone': patientData['phone'] ?? '',
          'age': patientData['age'] ?? '',
          'medicalConditions': patientData['medicalConditions'] ?? '',
          'assignedAt': assignmentData['assignedAt'],
          'adherencePercentage': adherencePercentage,
          'medicationCount': medicationCount,
          'recentActivity': recentLogs.isNotEmpty ? 'Active' : 'No recent activity',
          'lastMedicationDate': recentLogs.isNotEmpty 
              ? (recentLogs.first.data()['takenAt'] as Timestamp?)?.toDate()
              : null,
        });
      }
    } catch (e) {
      debugPrint('Error loading patient $patientId details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _switchToPatient(String patientId) async {
    try {
      // Store selected patient ID in shared preferences
      await _offlineService.saveLocalData('caregiver_preferences', 'selected_patient', {
        'patientId': patientId,
        'selectedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _selectedPatientId = patientId;
      });

      _showSuccessSnackBar('Switched to patient profile');
      
      // Navigate to caregiver dashboard with patient context
      Navigator.pushReplacementNamed(context, '/caregiver_dashboard');
    } catch (e) {
      _showErrorSnackBar('Error switching to patient: $e');
    }
  }

  Future<void> _viewPatientDetails(Map<String, dynamic> patient) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient Details: ${patient['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', patient['name']),
              _buildDetailRow('Email', patient['email']),
              if (patient['phone']?.isNotEmpty == true)
                _buildDetailRow('Phone', patient['phone']),
              if (patient['age']?.isNotEmpty == true)
                _buildDetailRow('Age', patient['age']),
              if (patient['medicalConditions']?.isNotEmpty == true)
                _buildDetailRow('Medical Conditions', patient['medicalConditions']),
              _buildDetailRow('Medications', '${patient['medicationCount']} medications'),
              _buildDetailRow('Adherence', '${patient['adherencePercentage']}% (last 7 days)'),
              _buildDetailRow('Recent Activity', patient['recentActivity']),
              if (patient['lastMedicationDate'] != null)
                _buildDetailRow('Last Medication', _formatDate(patient['lastMedicationDate'])),
              if (patient['assignedAt'] != null)
                _buildDetailRow('Assigned Since', _formatDate(patient['assignedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _switchToPatient(patient['id']);
            },
            child: const Text('Switch to Patient'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    } else if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPatientAdherence(String patientId, String patientName) async {
    Navigator.pushNamed(
      context,
      '/patient_adherence',
      arguments: {'patientId': patientId, 'patientName': patientName},
    );
  }

  Future<void> _removePatientAssignment(String patientId, String patientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Patient'),
        content: Text('Are you sure you want to remove $patientName from your assigned patients?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        // Remove assignment
        final assignmentQuery = await _firestore
            .collection('caregiver_assignments')
            .where('caregiverId', isEqualTo: user.uid)
            .where('patientId', isEqualTo: patientId)
            .get();

        for (final doc in assignmentQuery.docs) {
          await doc.reference.delete();
        }

        // Update patient's assigned caregiver
        await _firestore
            .collection('users')
            .doc(patientId)
            .update({'assignedCaregiverId': null});

        _showSuccessSnackBar('Patient removed successfully');
        await _loadAssignedPatients();
      } catch (e) {
        _showErrorSnackBar('Error removing patient: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profiles'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            onPressed: _loadAssignedPatients,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedPatients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Patients Assigned',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patients will appear here once they assign themselves to you',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignedPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _assignedPatients[index];
                    final isSelected = patient['id'] == _selectedPatientId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 2,
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.blue : Colors.grey,
                          child: Text(
                            patient['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          patient['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient['email']),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.medication,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${patient['medicationCount']} meds',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${patient['adherencePercentage']}% adherence',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _viewPatientDetails(patient),
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              onPressed: () => _viewPatientAdherence(
                                patient['id'],
                                patient['name'],
                              ),
                              icon: const Icon(Icons.analytics),
                              tooltip: 'View Adherence',
                              color: Colors.green,
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'switch':
                                    _switchToPatient(patient['id']);
                                    break;
                                  case 'remove':
                                    _removePatientAssignment(patient['id'], patient['name']);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'switch',
                                  child: Row(
                                    children: [
                                      Icon(Icons.swap_horiz),
                                      SizedBox(width: 8),
                                      Text('Switch to Patient'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_remove, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Remove Patient', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _assignedPatients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show quick actions
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.analytics),
                          title: const Text('View All Adherence Reports'),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to a summary view
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Send Reminders to All'),
                          onTap: () {
                            Navigator.pop(context);
                            // Implement bulk reminder functionality
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.more_vert),
              label: const Text('Quick Actions'),
            )
          : null,
    );
  }
} 