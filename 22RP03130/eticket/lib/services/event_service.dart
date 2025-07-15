import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final _events = FirebaseFirestore.instance.collection('events');

  Future<void> createEvent(Event event) async {
    await _events.add(event.toMap());
  }

  Stream<List<Event>> getEvents() {
    return _events.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Event.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }

  // Add update and delete methods as needed
} 