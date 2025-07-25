import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:async';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import '../services/firebase_service.dart';

class QuizProvider extends ChangeNotifier {
  List<QuizAttempt> _quizAttempts = [];
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();
  final _random = Random();
  StreamSubscription<List<QuizAttempt>>? _quizAttemptsSubscription;
  bool _isInitialized = false;

  List<QuizAttempt> get quizAttempts => _quizAttempts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get attemptsCount => _quizAttempts.length;
  bool get isInitialized => _isInitialized;

  void initialize(String userId) {
    if (_isInitialized) return;
    _isInitialized = true;
    _loadQuizAttempts(userId);
  }



  Future<void> _loadQuizAttempts(String userId) async {
    try {
      print('DEBUG: QuizProvider - Starting to load quiz attempts for user: $userId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel any existing subscription
      await _quizAttemptsSubscription?.cancel();
      
      // Set up new subscription
      _quizAttemptsSubscription = FirebaseService.getUserQuizAttempts(userId).listen(
        (attempts) {
          print('DEBUG: QuizProvider - Received ${attempts.length} quiz attempts from Firebase for user: $userId');
          _quizAttempts = attempts;
          _error = null;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('DEBUG: QuizProvider - Error loading quiz attempts: $error');
          _error = 'Failed to load quiz attempts: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('DEBUG: QuizProvider - Exception loading quiz attempts: $e');
      _error = 'Failed to load quiz attempts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _quizAttemptsSubscription?.cancel();
    super.dispose();
  }

  // Generate quiz from flashcards
  QuizModel generateQuizFromFlashcards(
    List<FlashcardModel> flashcards,
    String userId,
    String title,
  ) {
    final List<QuizQuestion> questions = [];
    final shuffledFlashcards = List<FlashcardModel>.from(flashcards)..shuffle(_random);
    
    // Take up to 10 flashcards for the quiz
    final selectedFlashcards = shuffledFlashcards.take(10).toList();
    
    for (final flashcard in selectedFlashcards) {
      final options = _generateOptions(flashcard.answer, flashcards);
      questions.add(QuizQuestion(
        question: flashcard.question,
        correctAnswer: flashcard.answer,
        options: options,
      ));
    }

    return QuizModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      questions: questions,
      createdAt: DateTime.now(),
    );
  }

  List<String> _generateOptions(String correctAnswer, List<FlashcardModel> allFlashcards) {
    final options = [correctAnswer];
    final otherAnswers = allFlashcards
        .where((f) => f.answer != correctAnswer)
        .map((f) => f.answer)
        .toList();
    
    // Shuffle and take 3 random wrong answers
    otherAnswers.shuffle(_random);
    options.addAll(otherAnswers.take(3));
    
    // Shuffle all options
    options.shuffle(_random);
    return options;
  }

  Future<bool> saveQuizAttempt(QuizAttempt attempt) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.saveQuizAttempt(attempt);
      return true;
    } catch (e) {
      _error = 'Failed to save quiz attempt: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate quiz statistics
  double getAverageScore() {
    if (_quizAttempts.isEmpty) return 0.0;
    final totalPercentage = _quizAttempts.fold<double>(
      0.0,
      (sum, attempt) => sum + attempt.percentage,
    );
    return totalPercentage / _quizAttempts.length;
  }

  int getTotalQuestionsAnswered() {
    return _quizAttempts.fold<int>(
      0,
      (sum, attempt) => sum + attempt.totalQuestions,
    );
  }

  int getTotalCorrectAnswers() {
    return _quizAttempts.fold<int>(
      0,
      (sum, attempt) => sum + attempt.score,
    );
  }

  List<QuizAttempt> getRecentAttempts(int count) {
    return _quizAttempts.take(count).toList();
  }

  List<QuizAttempt> getAttemptsByDateRange(DateTime start, DateTime end) {
    return _quizAttempts.where((attempt) {
      return attempt.attemptedAt.isAfter(start) && 
             attempt.attemptedAt.isBefore(end);
    }).toList();
  }

  // Get performance by day for streak calculation
  Map<DateTime, List<QuizAttempt>> getAttemptsByDay() {
    final Map<DateTime, List<QuizAttempt>> attemptsByDay = {};
    
    for (final attempt in _quizAttempts) {
      final day = DateTime(
        attempt.attemptedAt.year,
        attempt.attemptedAt.month,
        attempt.attemptedAt.day,
      );
      
      if (attemptsByDay.containsKey(day)) {
        attemptsByDay[day]!.add(attempt);
      } else {
        attemptsByDay[day] = [attempt];
      }
    }
    
    return attemptsByDay;
  }

  int getCurrentStreak() {
    final attemptsByDay = getAttemptsByDay();
    final sortedDays = attemptsByDay.keys.toList()..sort();
    
    if (sortedDays.isEmpty) return 0;
    
    int streak = 0;
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    
    // Check if user has attempted today or yesterday
    bool hasRecentAttempt = false;
    for (final day in sortedDays.reversed) {
      if (day.isAfter(yesterday)) {
        hasRecentAttempt = true;
        break;
      }
    }
    
    if (!hasRecentAttempt) return 0;
    
    // Calculate consecutive days
    DateTime? currentDate = sortedDays.last;
    for (int i = sortedDays.length - 1; i >= 0; i--) {
      final day = sortedDays[i];
      final expectedDate = currentDate!.subtract(Duration(days: streak));
      
      if (day.year == expectedDate.year &&
          day.month == expectedDate.month &&
          day.day == expectedDate.day) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 