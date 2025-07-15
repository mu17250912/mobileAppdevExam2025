import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../utils/constants.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save event to Firestore
  static Future<void> createEvent(EventModel event) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(event.id)
        .set(event.toJson());
  }

  // Fetch all events from Firestore
  static Future<List<EventModel>> getAllEvents() async {
    final query = await _firestore.collection(AppConstants.eventsCollection).get();
    return query.docs.map((doc) => EventModel.fromJson(doc.data())).toList();
  }

  static Future<void> updateEventStatus(String eventId, String status) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .update({'status': status, 'updatedAt': DateTime.now().toIso8601String()});
  }

  // Optionally, add update and delete methods here
} 