import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/flashcard_model.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardModel> _flashcards = [];
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();
  StreamSubscription<List<FlashcardModel>>? _flashcardsSubscription;
  bool _isInitialized = false;

  List<FlashcardModel> get flashcards => _flashcards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get flashcardsCount => _flashcards.length;
  int get studiedCount => _flashcards.where((f) => f.isStudied).length;
  bool get isInitialized => _isInitialized;

  void initialize(String userId) {
    if (_isInitialized) return;
    _isInitialized = true;
    _loadFlashcards(userId);
  }

  Future<void> _loadFlashcards(String userId) async {
    try {
      print('DEBUG: FlashcardProvider - Starting to load flashcards for user: $userId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel any existing subscription
      await _flashcardsSubscription?.cancel();
      
      // Set up new subscription
      _flashcardsSubscription = FirebaseService.getUserFlashcards(userId).listen(
        (flashcards) {
          print('DEBUG: FlashcardProvider - Received ${flashcards.length} flashcards from Firebase');
          _flashcards = flashcards;
          _error = null;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('DEBUG: FlashcardProvider - Error loading flashcards: $error');
          _error = 'Failed to load flashcards: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('DEBUG: FlashcardProvider - Exception loading flashcards: $e');
      _error = 'Failed to load flashcards: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _flashcardsSubscription?.cancel();
    super.dispose();
  }

  Future<bool> addFlashcard({
    required String userId,
    required String question,
    required String answer,
    String? noteId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final flashcard = FlashcardModel(
        id: _uuid.v4(),
        userId: userId,
        question: question.trim(),
        answer: answer.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        noteId: noteId,
      );

      await FirebaseService.addFlashcard(flashcard);
      return true;
    } catch (e) {
      _error = 'Failed to add flashcard: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFlashcard({
    required String flashcardId,
    required String question,
    required String answer,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existingFlashcard = _flashcards.firstWhere((f) => f.id == flashcardId);
      final updatedFlashcard = existingFlashcard.copyWith(
        question: question.trim(),
        answer: answer.trim(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateFlashcard(updatedFlashcard);
      return true;
    } catch (e) {
      _error = 'Failed to update flashcard: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFlashcard(String flashcardId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.deleteFlashcard(flashcardId);
      return true;
    } catch (e) {
      _error = 'Failed to delete flashcard: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsStudied(String flashcardId) async {
    try {
      final existingFlashcard = _flashcards.firstWhere((f) => f.id == flashcardId);
      final updatedFlashcard = existingFlashcard.copyWith(
        isStudied: true,
        studyCount: existingFlashcard.studyCount + 1,
        lastStudiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateFlashcard(updatedFlashcard);
      return true;
    } catch (e) {
      _error = 'Failed to mark flashcard as studied: $e';
      notifyListeners();
      return false;
    }
  }

  // Generate flashcards from note content
  List<FlashcardModel> generateFromNote(NoteModel note, String userId) {
    final List<FlashcardModel> generatedFlashcards = [];
    final content = note.content;
    
    // Simple algorithm to extract potential Q&A pairs
    final sentences = content.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).toList();
    
    for (int i = 0; i < sentences.length - 1; i += 2) {
      if (i + 1 < sentences.length) {
        final question = sentences[i].trim();
        final answer = sentences[i + 1].trim();
        
        if (question.length > 10 && answer.length > 5) {
          final flashcard = FlashcardModel(
            id: _uuid.v4(),
            userId: userId,
            question: _formatQuestion(question),
            answer: answer,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            noteId: note.id,
          );
          generatedFlashcards.add(flashcard);
        }
      }
    }
    
    return generatedFlashcards;
  }

  String _formatQuestion(String sentence) {
    // Convert statement to question format
    final words = sentence.split(' ');
    if (words.isNotEmpty) {
      final firstWord = words[0].toLowerCase();
      if (firstWord == 'the' || firstWord == 'a' || firstWord == 'an') {
        return 'What is ${sentence.substring(firstWord.length + 1)}?';
      } else {
        return 'What is $sentence?';
      }
    }
    return 'What is $sentence?';
  }

  Future<bool> generateFlashcardsFromNote(NoteModel note, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final generatedFlashcards = generateFromNote(note, userId);
      
      for (final flashcard in generatedFlashcards) {
        await FirebaseService.addFlashcard(flashcard);
      }

      return true;
    } catch (e) {
      _error = 'Failed to generate flashcards: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<FlashcardModel> getUnstudiedFlashcards() {
    return _flashcards.where((f) => !f.isStudied).toList();
  }

  List<FlashcardModel> getStudiedFlashcards() {
    return _flashcards.where((f) => f.isStudied).toList();
  }

  List<FlashcardModel> getFlashcardsByNote(String noteId) {
    return _flashcards.where((f) => f.noteId == noteId).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 