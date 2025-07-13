import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Create a new event
  Future<String> createEvent(Event event) async {
    try {
      print('Creating event: ${event.title}');
      
      final eventId = _uuid.v4();
      final eventWithId = event.copyWith(
        id: eventId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eventData = eventWithId.toMap();
      print('Event data to save: $eventData');

      await _firestore
          .collection('events')
          .doc(eventId)
          .set(eventData);

      print('Event created successfully with ID: $eventId');
      return eventId;
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  // Get all events (completely simplified)
  Stream<List<Event>> getAllEvents() {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
      // Filter and sort in memory
      final publicEvents = events.where((event) => !event.isPrivate).toList();
      publicEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return publicEvents;
    });
  }

  // Get events by organizer (simplified)
  Stream<List<Event>> getEventsByOrganizer(String organizerId) {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
      // Filter and sort in memory
      final organizerEvents = events.where((event) => event.organizerId == organizerId).toList();
      organizerEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return organizerEvents;
    });
  }

  // Get events user is participating in (simplified)
  Stream<List<Event>> getEventsByParticipant(String userId) {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
      // Filter and sort in memory
      final participatingEvents = events.where((event) => event.participants.contains(userId)).toList();
      participatingEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return participatingEvents;
    });
  }

  // Get single event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return Event.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // Update event
  Future<void> updateEvent(Event event) async {
    try {
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('events')
          .doc(event.id)
          .update(updatedEvent.toMap());
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .delete();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Join event
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error joining event: $e');
      rethrow;
    }
  }

  // Leave event
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error leaving event: $e');
      rethrow;
    }
  }

  // Search events (simplified)
  Stream<List<Event>> searchEvents(String query) {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
      // Filter in memory
      final publicEvents = events.where((event) => !event.isPrivate).toList();
      return publicEvents.where((event) => 
        event.title.toLowerCase().contains(query.toLowerCase()) ||
        event.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Get upcoming events (simplified)
  Stream<List<Event>> getUpcomingEvents() {
    final now = DateTime.now();
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
      // Filter and sort in memory
      final publicEvents = events.where((event) => !event.isPrivate).toList();
      final upcomingEvents = publicEvents
          .where((event) => event.dateTime.isAfter(now))
          .toList();
      upcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return upcomingEvents.take(10).toList();
    });
  }
} 