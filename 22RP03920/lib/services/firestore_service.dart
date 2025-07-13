import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get doctorsCollection => _firestore.collection('doctors');
  CollectionReference get notificationsCollection => _firestore.collection('notifications');
  CollectionReference get paymentsCollection => _firestore.collection('payments');

  // Add a doctor
  Future<void> addDoctor(Map<String, dynamic> doctorData) async {
    await doctorsCollection.add(doctorData);
  }

  // Delete a doctor
  Future<void> deleteDoctor(String doctorId) async {
    await doctorsCollection.doc(doctorId).delete();
  }

  // Get doctor's name from Firestore
  Future<String?> getDoctorName(String doctorId) async {
    final doc = await usersCollection.doc(doctorId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'];
    }
    return null;
  }

  // Get all appointments for a doctor
  Stream<QuerySnapshot> getDoctorAppointments(String doctorId) {
    return appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get today's appointments for a doctor
  Stream<QuerySnapshot> getTodayAppointments(String doctorId) {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: dateStr)
        .orderBy('timeSlot')
        .snapshots();
  }

  // Get upcoming appointments for a doctor
  Stream<QuerySnapshot> getUpcomingAppointments(String doctorId) {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return appointmentsCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThan: dateStr)
        .orderBy('date')
        .orderBy('timeSlot')
        .snapshots();
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await appointmentsCollection.doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Fetch appointment details
    final doc = await appointmentsCollection.doc(appointmentId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final patientId = data['patientId'];
    final doctorName = data['doctorName'] ?? '';
    final date = data['date'] ?? '';
    final timeSlot = data['timeSlot'] ?? '';

    if (patientId != null && (status == 'approved' || status == 'rejected')) {
      String notifType = status == 'approved' ? 'appointment_approved' : 'appointment_rejected';
      String notifTitle = status == 'approved' ? 'Appointment Approved' : 'Appointment Rejected';
      String notifMsg = status == 'approved'
        ? 'Your appointment with Dr. $doctorName on $date at $timeSlot has been approved.'
        : 'Your appointment with Dr. $doctorName on $date at $timeSlot has been rejected.';
      await notificationsCollection.add({
        'userId': patientId,
        'type': notifType,
        'title': notifTitle,
        'message': notifMsg,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  // Get appointments for a patient
  Stream<QuerySnapshot> getAppointmentsForUser(String userId) {
    return appointmentsCollection
        .where('patientId', isEqualTo: userId)
        .snapshots();
  }
  
  // Get all doctors
  Stream<QuerySnapshot> getDoctors() {
    return usersCollection.where('role', isEqualTo: 'doctor').snapshots();
  }

  // Get doctor's availability
  Future<Map<String, dynamic>?> getDoctorAvailability(String doctorId) async {
    final doc = await doctorsCollection.doc(doctorId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Update doctor's availability
  Future<void> updateDoctorAvailability(String doctorId, Map<String, dynamic> availability) async {
    await doctorsCollection.doc(doctorId).update(availability);
  }

  // Store payment details
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    await paymentsCollection.add(paymentData);
  }
} 