import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _userEvents = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EventModel> get events => _events;
  List<EventModel> get userEvents => _userEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all events
  Future<void> loadEvents() async {
    _setLoading(true);
    _clearError();
    try {
      final events = await EventService.getAllEvents();
      _events = events;
      // Optionally, update userEvents if current user is available
      // _userEvents = _events.where((event) => event.organizerId == currentUserId).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user events (fetch from Firestore directly)
  Future<void> loadUserEvents(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      await loadEvents(); // Always refresh all events first
      _userEvents = _events.where((event) => event.organizerId == userId).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create new event
  Future<bool> createEvent(EventModel event) async {
    _setLoading(true);
    _clearError();
    
    try {
      await EventService.createEvent(event);
      _events.add(event);
      _userEvents.add(event);
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      NotificationService.showSuccessNotification(
        title: 'Event Created',
        message: 'Your event has been created successfully!',
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update event
  Future<bool> updateEvent(EventModel event) async {
    _setLoading(true);
    _clearError();
    try {
      // Update event in Firestore
      await EventService.createEvent(event); // Overwrites the event document
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        NotificationService.showSuccessNotification(
          title: 'Event Updated',
          message: 'Your event has been updated successfully!',
        );
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement event deletion in Firestore
      _events.removeWhere((event) => event.id == eventId);
      _userEvents.removeWhere((event) => event.id == eventId);
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
              });
        NotificationService.showSuccessNotification(
          title: 'Event Deleted',
          message: 'Your event has been deleted successfully!',
        );
        return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get events by type
  List<EventModel> getEventsByType(String eventType) {
    return _events.where((event) => event.eventType == eventType).toList();
  }

  // Search events
  List<EventModel> searchEvents(String query) {
    if (query.isEmpty) return _events;
    
    return _events.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
             event.description.toLowerCase().contains(query.toLowerCase()) ||
             event.location.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set error
  void _setError(String error) {
    _error = error;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error
  void _clearError() {
    _error = null;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
} 