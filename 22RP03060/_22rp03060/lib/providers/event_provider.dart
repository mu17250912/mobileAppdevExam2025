import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  
  List<Event> _allEvents = [];
  List<Event> _myEvents = [];
  List<Event> _participatingEvents = [];
  List<Event> _upcomingEvents = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  List<Event> get allEvents => _allEvents;
  List<Event> get myEvents => _myEvents;
  List<Event> get participatingEvents => _participatingEvents;
  List<Event> get upcomingEvents => _upcomingEvents;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EventProvider() {
    _init();
  }

  void _init() {
    _loadAllEvents();
    _loadUpcomingEvents();
  }

  void _loadAllEvents() {
    _eventService.getAllEvents().listen((events) {
      _allEvents = events;
      notifyListeners();
    });
  }

  void _loadUpcomingEvents() {
    _eventService.getUpcomingEvents().listen((events) {
      _upcomingEvents = events;
      notifyListeners();
    });
  }

  void loadMyEvents(String userId) {
    _eventService.getEventsByOrganizer(userId).listen((events) {
      _myEvents = events;
      notifyListeners();
    });
  }

  void loadParticipatingEvents(String userId) {
    _eventService.getEventsByParticipant(userId).listen((events) {
      _participatingEvents = events;
      notifyListeners();
    });
  }

  Future<bool> createEvent(Event event) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.createEvent(event);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh all event data
      _refreshAllData();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(Event event) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.updateEvent(event);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh all event data
      _refreshAllData();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.deleteEvent(eventId);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh all event data
      _refreshAllData();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinEvent(String eventId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.joinEvent(eventId, userId);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh all event data
      _refreshAllData();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.leaveEvent(eventId, userId);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh all event data
      _refreshAllData();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      return await _eventService.getEventById(eventId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void setSelectedEvent(Event? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Event> searchEvents(String query) {
    if (query.isEmpty) return _allEvents;
    
    return _allEvents.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
             event.description.toLowerCase().contains(query.toLowerCase()) ||
             event.location.toLowerCase().contains(query.toLowerCase()) ||
             event.categories.any((category) => 
                 category.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  List<Event> getEventsByCategory(String category) {
    return _allEvents.where((event) {
      return event.categories.contains(category);
    }).toList();
  }

  // Helper method to refresh all event data
  void _refreshAllData() {
    _loadAllEvents();
    _loadUpcomingEvents();
  }
} 