import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class CaregiverInfoScreen extends StatefulWidget {
  final String? caregiverId;
  
  const CaregiverInfoScreen({super.key, this.caregiverId});

  @override
  State<CaregiverInfoScreen> createState() => _CaregiverInfoScreenState();
}

class _CaregiverInfoScreenState extends State<CaregiverInfoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, dynamic>? _caregiverData;
  List<Map<String, dynamic>> _assignedPatients = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadCaregiverInfo();
  }

  Future<void> _loadCaregiverInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? caregiverId = widget.caregiverId;
      
      // If no specific caregiver ID provided, check if current user has an assigned caregiver
      if (caregiverId == null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userRole = userData['role'] as String?;
          
          if (userRole == 'caregiver') {
            // Current user is a caregiver, show their own profile
            caregiverId = currentUser.uid;
            _isCurrentUser = true;
          } else if (userRole == 'patient') {
            // Current user is a patient, get their assigned caregiver
            caregiverId = userData['assignedCaregiverId'] as String?;
            _isCurrentUser = false;
          }
        }
      } else {
        // Specific caregiver ID provided, check if it's the current user
        _isCurrentUser = currentUser.uid == caregiverId;
      }

      if (caregiverId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load caregiver data
      final caregiverDoc = await _firestore
          .collection('users')
          .doc(caregiverId)
          .get();

      if (caregiverDoc.exists) {
        final data = caregiverDoc.data()!;
        setState(() {
          _caregiverData = data;
        });

        // Load assigned patients if this is a caregiver profile
        if (data['role'] == 'caregiver') {
          await _loadAssignedPatients(caregiverId);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading caregiver information: $e');
    }
  }

  Future<void> _loadAssignedPatients(String caregiverId) async {
    try {
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

      setState(() {
        _assignedPatients = patients;
      });
    } catch (e) {
      debugPrint('Error loading assigned patients: $e');
    }
  }

  Future<void> _assignCaregiver() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || _caregiverData == null) return;

      // Update user's assigned caregiver
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'assignedCaregiverId': widget.caregiverId,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // Create caregiver assignment record
      await _firestore
          .collection('caregiver_assignments')
          .add({
        'patientId': currentUser.uid,
        'caregiverId': widget.caregiverId,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      _showSuccessSnackBar('Successfully assigned to caregiver!');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error assigning caregiver: $e');
    }
  }

  Future<void> _removeAssignment(String patientId) async {
    try {
      // Remove caregiver assignment from patient
      await _firestore
          .collection('users')
          .doc(patientId)
          .update({
        'assignedCaregiverId': null,
        'assignedAt': null,
      });

      // Update assignment status
      final assignmentQuery = await _firestore
          .collection('caregiver_assignments')
          .where('patientId', isEqualTo: patientId)
          .where('caregiverId', isEqualTo: widget.caregiverId)
          .get();

      for (final doc in assignmentQuery.docs) {
        await doc.reference.update({
          'status': 'removed',
          'removedAt': FieldValue.serverTimestamp(),
        });
      }

      _showSuccessSnackBar('Patient assignment removed successfully');
      await _loadAssignedPatients(widget.caregiverId!);
    } catch (e) {
      _showErrorSnackBar('Error removing assignment: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _caregiverData == null
              ? _buildNoCaregiverView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caregiver Profile Card
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      
                      // Contact Information
                      _buildContactInfo(),
                      const SizedBox(height: 24),
                      
                      // Assigned Patients (only show for caregivers viewing their own profile)
                      if (_isCurrentUser && _assignedPatients.isNotEmpty)
                        _buildAssignedPatients(),
                      
                      // Assign Button (if not current user)
                      if (!_isCurrentUser && widget.caregiverId != null)
                        _buildAssignButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _caregiverData!['name']?.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _caregiverData!['name'] ?? 'Unknown Caregiver',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Caregiver',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_caregiverData!['bio'] != null) ...[
              const SizedBox(height: 16),
              Text(
                _caregiverData!['bio'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              'Email',
              _caregiverData!['email'] ?? 'Not provided',
            ),
            if (_caregiverData!['phone'] != null)
              _buildContactItem(
                Icons.phone,
                'Phone',
                _caregiverData!['phone'],
              ),
            if (_caregiverData!['location'] != null)
              _buildContactItem(
                Icons.location_on,
                'Location',
                _caregiverData!['location'],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedPatients() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Patients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_assignedPatients.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_assignedPatients.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No patients assigned yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _assignedPatients.length,
                itemBuilder: (context, index) {
                  final patient = _assignedPatients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        patient['name']?.substring(0, 1).toUpperCase() ?? 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patient['name'] ?? 'Unknown Patient',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      patient['email'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: _isCurrentUser
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            onPressed: () => _removeAssignment(patient['id']),
                          )
                        : null,
                    onTap: () {
                      // Navigate to patient details if needed
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _assignCaregiver,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Assign This Caregiver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isCurrentUser) {
      return 'My Profile';
    } else if (_caregiverData != null) {
      return 'My Caregiver';
    } else {
      return 'Caregiver Information';
    }
  }

  Widget _buildNoCaregiverView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Caregiver Assigned',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have a caregiver assigned yet. A caregiver can help you manage your medications and provide support.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/caregiver_assignment');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Find a Caregiver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
} 