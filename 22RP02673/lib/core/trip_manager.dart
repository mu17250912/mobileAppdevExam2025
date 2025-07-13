import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripManager {
  // Firestore-based CRUD for ride requests and trips

  static CollectionReference get _rideRequests => FirebaseFirestore.instance.collection('rideRequests');
  static CollectionReference get _trips => FirebaseFirestore.instance.collection('trips');

  static Future<DocumentReference> addRideRequest(Map<String, dynamic> request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user signed in');
    request['status'] = 'pending';
    request['passengerId'] = user.uid;
    request['createdAt'] = FieldValue.serverTimestamp();
    return await _rideRequests.add(request);
  }

  static Future<void> acceptRideRequest(String requestId, String driverId) async {
    await _rideRequests.doc(requestId).update({
      'status': 'accepted',
      'driverId': driverId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    // Optionally, move to trips collection
    // final doc = await _rideRequests.doc(requestId).get();
    // await _trips.add(doc.data()!);
  }

  static Future<void> declineRideRequest(String requestId) async {
    await _rideRequests.doc(requestId).update({'status': 'declined'});
  }

  static Future<void> markArrived(String requestId) async {
    await _rideRequests.doc(requestId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> startRide(String requestId) async {
    await _rideRequests.doc(requestId).update({
      'status': 'started',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeRide(String requestId) async {
    await _rideRequests.doc(requestId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> cancelRide(String requestId, String reason) async {
    await _rideRequests.doc(requestId).update({
      'status': 'cancelled',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getPassengerTrips() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user signed in');
    return _rideRequests.where('passengerId', isEqualTo: user.uid).snapshots();
  }

  static Stream<QuerySnapshot> getDriverTrips() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user signed in');
    return _rideRequests.where('driverId', isEqualTo: user.uid).snapshots();
  }

  static Stream<QuerySnapshot> getPendingRideRequestsForDriver() {
    return _rideRequests.where('status', isEqualTo: 'pending').snapshots();
  }
} 