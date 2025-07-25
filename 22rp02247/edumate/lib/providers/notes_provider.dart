import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/note_model.dart';
import '../services/firebase_service.dart';

class NotesProvider extends ChangeNotifier {
  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();
  StreamSubscription<List<NoteModel>>? _notesSubscription;

  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get notesCount => _notes.length;

  void initialize(String userId) {
    print('NotesProvider: Initializing for user: $userId');
    _loadNotes(userId);
  }

  Future<void> _loadNotes(String userId) async {
    print('NotesProvider: Loading notes for user: $userId');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel any existing subscription
      await _notesSubscription?.cancel();
      
      print('NotesProvider: Setting up stream subscription');
      
      // Set up new subscription
      _notesSubscription = FirebaseService.getUserNotes(userId).listen(
        (notes) {
          print('NotesProvider: Received ${notes.length} notes from stream');
          _notes = notes;
          _error = null;
          _isLoading = false;
          notifyListeners();
          print('NotesProvider: Notified listeners with ${_notes.length} notes');
        },
        onError: (error) {
          print('NotesProvider: Error in stream: $error');
          _error = 'Failed to load notes: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
      
      print('NotesProvider: Stream subscription set up successfully');
    } catch (e) {
      print('NotesProvider: Error in _loadNotes: $e');
      _error = 'Failed to load notes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  Future<bool> addNote({
    required String userId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    print('NotesProvider: Adding note for user: $userId');
    print('NotesProvider: Note title: $title');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final note = NoteModel(
        id: _uuid.v4(),
        userId: userId,
        title: title.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: tags,
      );

      print('NotesProvider: Created note: ${note.toMap()}');
      await FirebaseService.addNote(note);
      print('NotesProvider: Note added successfully to Firebase');
      
      return true;
    } catch (e) {
      print('NotesProvider: Error adding note: $e');
      _error = 'Failed to add note: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNote({
    required String noteId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existingNote = _notes.firstWhere((note) => note.id == noteId);
      final updatedNote = existingNote.copyWith(
        title: title.trim(),
        content: content.trim(),
        updatedAt: DateTime.now(),
        tags: tags,
      );

      await FirebaseService.updateNote(updatedNote);
      return true;
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.deleteNote(noteId);
      return true;
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    
    final lowercaseQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  List<NoteModel> getNotesByTag(String tag) {
    return _notes.where((note) => note.tags.contains(tag)).toList();
  }

  List<String> getAllTags() {
    final Set<String> tags = {};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshNotes(String userId) async {
    print('NotesProvider: Manually refreshing notes for user: $userId');
    await _loadNotes(userId);
  }

  Future<void> testNotesRetrieval(String userId) async {
    await FirebaseService.testNotesRetrieval(userId);
  }

  Future<void> createTestNote(String userId) async {
    await FirebaseService.createTestNote(userId);
  }
} 