import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import '../models/note_model.dart';

class ProgressProvider extends ChangeNotifier {
  List<FlashcardModel> _flashcards = [];
  List<QuizAttempt> _quizAttempts = [];
  List<NoteModel> _notes = [];
  bool _isLoading = false;

  List<FlashcardModel> get flashcards => _flashcards;
  List<QuizAttempt> get quizAttempts => _quizAttempts;
  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;

  void updateData({
    required List<FlashcardModel> flashcards,
    required List<QuizAttempt> quizAttempts,
    required List<NoteModel> notes,
  }) {
    _flashcards = flashcards;
    _quizAttempts = quizAttempts;
    _notes = notes;
    notifyListeners();
  }

  // Overall Progress Statistics
  int get totalNotes => _notes.length;
  int get totalFlashcards => _flashcards.length;
  int get totalQuizAttempts => _quizAttempts.length;
  int get studiedFlashcards => _flashcards.where((f) => f.isStudied).length;
  int get totalQuestionsAnswered => _quizAttempts.fold<int>(
    0,
    (sum, attempt) => sum + attempt.totalQuestions,
  );
  int get totalCorrectAnswers => _quizAttempts.fold<int>(
    0,
    (sum, attempt) => sum + attempt.score,
  );

  double get flashcardCompletionRate {
    if (_flashcards.isEmpty) return 0.0;
    return (studiedFlashcards / _flashcards.length) * 100;
  }

  double get averageQuizScore {
    if (_quizAttempts.isEmpty) return 0.0;
    final totalPercentage = _quizAttempts.fold<double>(
      0.0,
      (sum, attempt) => sum + attempt.percentage,
    );
    return totalPercentage / _quizAttempts.length;
  }

  // Study Streak
  int get currentStreak {
    if (_quizAttempts.isEmpty) return 0;
    
    final attemptsByDay = <DateTime, List<QuizAttempt>>{};
    
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

  // Weekly Progress
  List<Map<String, dynamic>> get weeklyProgress {
    final List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayAttempts = _quizAttempts.where((attempt) {
        return attempt.attemptedAt.isAfter(dayStart) && 
               attempt.attemptedAt.isBefore(dayEnd);
      }).toList();
      
      final dayFlashcards = _flashcards.where((flashcard) {
        return flashcard.lastStudiedAt != null &&
               flashcard.lastStudiedAt!.isAfter(dayStart) && 
               flashcard.lastStudiedAt!.isBefore(dayEnd);
      }).toList();
      
      weeklyData.add({
        'date': date,
        'quizAttempts': dayAttempts.length,
        'flashcardsStudied': dayFlashcards.length,
        'averageScore': dayAttempts.isEmpty ? 0.0 : 
            dayAttempts.fold<double>(0.0, (sum, attempt) => sum + attempt.percentage) / dayAttempts.length,
      });
    }
    
    return weeklyData;
  }

  // Monthly Progress
  List<Map<String, dynamic>> get monthlyProgress {
    final List<Map<String, dynamic>> monthlyData = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayAttempts = _quizAttempts.where((attempt) {
        return attempt.attemptedAt.isAfter(dayStart) && 
               attempt.attemptedAt.isBefore(dayEnd);
      }).toList();
      
      final dayFlashcards = _flashcards.where((flashcard) {
        return flashcard.lastStudiedAt != null &&
               flashcard.lastStudiedAt!.isAfter(dayStart) && 
               flashcard.lastStudiedAt!.isBefore(dayEnd);
      }).toList();
      
      monthlyData.add({
        'date': date,
        'quizAttempts': dayAttempts.length,
        'flashcardsStudied': dayFlashcards.length,
        'averageScore': dayAttempts.isEmpty ? 0.0 : 
            dayAttempts.fold<double>(0.0, (sum, attempt) => sum + attempt.percentage) / dayAttempts.length,
      });
    }
    
    return monthlyData;
  }

  // Subject/Topic Progress (based on note tags)
  Map<String, Map<String, dynamic>> get subjectProgress {
    final Map<String, List<NoteModel>> notesByTag = {};
    final Map<String, List<FlashcardModel>> flashcardsByTag = {};
    
    // Group notes by tags
    for (final note in _notes) {
      for (final tag in note.tags) {
        if (notesByTag.containsKey(tag)) {
          notesByTag[tag]!.add(note);
        } else {
          notesByTag[tag] = [note];
        }
      }
    }
    
    // Group flashcards by note tags
    for (final flashcard in _flashcards) {
      if (flashcard.noteId != null) {
        final note = _notes.firstWhere(
          (n) => n.id == flashcard.noteId,
          orElse: () => NoteModel(
            id: '',
            userId: '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        for (final tag in note.tags) {
          if (flashcardsByTag.containsKey(tag)) {
            flashcardsByTag[tag]!.add(flashcard);
          } else {
            flashcardsByTag[tag] = [flashcard];
          }
        }
      }
    }
    
    // Calculate progress for each subject
    final Map<String, Map<String, dynamic>> subjectProgress = {};
    
    for (final tag in notesByTag.keys) {
      final tagNotes = notesByTag[tag]!;
      final tagFlashcards = flashcardsByTag[tag] ?? [];
      final studiedFlashcards = tagFlashcards.where((f) => f.isStudied).length;
      
      subjectProgress[tag] = {
        'notesCount': tagNotes.length,
        'flashcardsCount': tagFlashcards.length,
        'studiedFlashcards': studiedFlashcards,
        'completionRate': tagFlashcards.isEmpty ? 0.0 : 
            (studiedFlashcards / tagFlashcards.length) * 100,
      };
    }
    
    return subjectProgress;
  }

  // Recent Activity
  List<Map<String, dynamic>> get recentActivity {
    final List<Map<String, dynamic>> activities = [];
    
    // Add recent notes
    for (final note in _notes.take(5)) {
      activities.add({
        'type': 'note_created',
        'title': note.title,
        'timestamp': note.createdAt,
        'icon': Icons.note,
      });
    }
    
    // Add recent flashcard studies
    final recentStudied = _flashcards
        .where((f) => f.lastStudiedAt != null)
        .toList()
      ..sort((a, b) => b.lastStudiedAt!.compareTo(a.lastStudiedAt!));
    
    for (final flashcard in recentStudied.take(5)) {
      activities.add({
        'type': 'flashcard_studied',
        'title': flashcard.question,
        'timestamp': flashcard.lastStudiedAt!,
        'icon': Icons.flip,
      });
    }
    
    // Add recent quiz attempts
    for (final attempt in _quizAttempts.take(5)) {
      activities.add({
        'type': 'quiz_completed',
        'title': 'Quiz - ${attempt.score}/${attempt.totalQuestions}',
        'timestamp': attempt.attemptedAt,
        'icon': Icons.quiz,
      });
    }
    
    // Sort by timestamp
    activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    return activities.take(10).toList();
  }

  // Achievement System
  List<Map<String, dynamic>> get achievements {
    final List<Map<String, dynamic>> achievements = [];
    
    // Notes achievements
    if (totalNotes >= 1) {
      achievements.add({
        'title': 'First Note',
        'description': 'Created your first study note',
        'icon': Icons.note,
        'unlocked': true,
      });
    }
    
    if (totalNotes >= 10) {
      achievements.add({
        'title': 'Note Taker',
        'description': 'Created 10 study notes',
        'icon': Icons.note,
        'unlocked': true,
      });
    }
    
    // Flashcard achievements
    if (totalFlashcards >= 1) {
      achievements.add({
        'title': 'Flashcard Creator',
        'description': 'Created your first flashcard',
        'icon': Icons.flip,
        'unlocked': true,
      });
    }
    
    if (studiedFlashcards >= 10) {
      achievements.add({
        'title': 'Dedicated Learner',
        'description': 'Studied 10 flashcards',
        'icon': Icons.flip,
        'unlocked': true,
      });
    }
    
    // Quiz achievements
    if (totalQuizAttempts >= 1) {
      achievements.add({
        'title': 'Quiz Taker',
        'description': 'Completed your first quiz',
        'icon': Icons.quiz,
        'unlocked': true,
      });
    }
    
    if (averageQuizScore >= 80) {
      achievements.add({
        'title': 'High Achiever',
        'description': 'Maintained 80%+ average score',
        'icon': Icons.star,
        'unlocked': true,
      });
    }
    
    // Streak achievements
    if (currentStreak >= 3) {
      achievements.add({
        'title': 'Consistent Learner',
        'description': 'Maintained a 3-day study streak',
        'icon': Icons.local_fire_department,
        'unlocked': true,
      });
    }
    
    if (currentStreak >= 7) {
      achievements.add({
        'title': 'Study Warrior',
        'description': 'Maintained a 7-day study streak',
        'icon': Icons.local_fire_department,
        'unlocked': true,
      });
    }
    
    return achievements;
  }
} 