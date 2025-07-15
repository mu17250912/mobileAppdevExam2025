import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'medication_form_screen.dart';
import '../services/notification_service.dart';
import '../services/voice_service.dart';
import '../services/emergency_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  bool _caregiverAssigned = false;
  bool _expandCaregiver = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VoiceService _voiceService = VoiceService();
  final EmergencyService _emergencyService = EmergencyService();

  @override
  void initState() {
    super.initState();
    _checkCaregiverAssignment();
    _scheduleReminders();
    _initializeVoiceService();
    // Show notification info for web users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNotificationInfo();
    });
  }

  Future<void> _checkCaregiverAssignment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final caregiverId = doc.data()?['assignedCaregiverId'];

    if (caregiverId != null) {
      setState(() {
        _caregiverAssigned = true;
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _toggleCaregiverExpand() {
    setState(() {
      _expandCaregiver = !_expandCaregiver;
    });
  }

    Future<void> _scheduleReminders() async {
    try {
      await NotificationService().requestPermissions();
      await NotificationService().scheduleMedicationReminders();
    } catch (e) {
      debugPrint('Error scheduling reminders: $e');
    }
  }

  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
    }
  }

  void _showNotificationInfo() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication reminders are not supported on web. Please use the mobile app for full functionality.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _callEmergencyContact() async {
    try {
      final primaryContact = await _emergencyService.getPrimaryContact();
      if (primaryContact != null) {
        await _voiceService.speakEmergencyContact(primaryContact.name, primaryContact.relationship);
        await _emergencyService.callContact(primaryContact);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contact set. Please add an emergency contact first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calling emergency contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Home"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            // Caregiver expandable section
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Caregiver'),
              trailing: Icon(
                _expandCaregiver ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: _toggleCaregiverExpand,
            ),

            if (_expandCaregiver) ...[
              ListTile(
                enabled: !_caregiverAssigned,
                leading: const Icon(Icons.person_add),
                title: const Text('Add Caregiver'),
                onTap: !_caregiverAssigned
                    ? () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/caregiver_assignment');
                      }
                    : null,
              ),
              ListTile(
                enabled: _caregiverAssigned,
                leading: const Icon(Icons.info),
                title: const Text('View Caregiver Info'),
                onTap: _caregiverAssigned
                    ? () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/caregiver_info');
                      }
                    : null,
              ),
            ],

            const Divider(),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Medication Adherence'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/medication_adherence');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar View'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/medication_calendar');
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.emergency),
              title: const Text('Emergency Contacts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/emergency_contacts');
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
                Navigator.pushNamed(context, '/patient_analytics');
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
                        Icons.medication,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to MedAlert',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your medications and health',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Emergency Contact Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _callEmergencyContact,
                  icon: const Icon(Icons.emergency, color: Colors.white),
                  label: const Text(
                    'EMERGENCY CONTACT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Caregiver Info Card
              if (_caregiverAssigned)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/caregiver_info');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'My Caregiver',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to view caregiver information',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Medications List
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
                      // Medications Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medication,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'My Medications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MedicationFormScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Medications List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _auth.currentUser != null
                              ? _firestore
                                  .collection('medications')
                                  .where('patientId', isEqualTo: _auth.currentUser!.uid)
                                  .snapshots()
                              : Stream.empty(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
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
                                      'Error loading medications',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: ${snapshot.error.toString()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (_auth.currentUser == null) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'User not authenticated',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
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

                            final medications = snapshot.data?.docs ?? [];

                            if (medications.isEmpty) {
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
                                        Icons.medication_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No medications added yet',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap the + button to add your first medication',
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
                              itemCount: medications.length,
                              itemBuilder: (context, index) {
                                final medication = medications[index].data() as Map<String, dynamic>;
                                final medicationId = medications[index].id;

                                return _buildMedicationCard(medication, medicationId);
                              },
                            );
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

  Widget _buildMedicationCard(Map<String, dynamic> medication, String medicationId) {
    final name = medication['name'] ?? '';
    final dosage = medication['dosage'] ?? '';
    final frequency = medication['frequency'] ?? '';
    final time = medication['time'] ?? '';
    final notes = medication['notes'] ?? '';

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
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
                        dosage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicationFormScreen(
                            medicationId: medicationId,
                            medication: medication,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteDialog(medicationId, name);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Frequency', frequency, Icons.schedule),
            _buildInfoRow('Times', time, Icons.access_time),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Notes', notes, Icons.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String medicationId, String medicationName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "$medicationName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMedication(medicationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(String medicationId) async {
    try {
      await _firestore.collection('medications').doc(medicationId).delete();
      
      // Cancel reminders for this medication
      await NotificationService().cancelMedicationReminders(medicationId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting medication: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
