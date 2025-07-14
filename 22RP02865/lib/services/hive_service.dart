import 'package:hive/hive.dart';
import '../models/task.dart';
import '../models/study_goal.dart';
import '../models/achievement.dart';
import '../models/flashcard.dart';
import '../models/exam.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;
  final Map<String, Box> _boxes = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure Hive is initialized with Flutter
      if (!Hive.isBoxOpen('tasks')) {
        // Register adapters
        Hive.registerAdapter(TaskAdapter());
        Hive.registerAdapter(StudyGoalAdapter());
        Hive.registerAdapter(AchievementAdapter());
        Hive.registerAdapter(AchievementTypeAdapter());
        Hive.registerAdapter(FlashcardAdapter());
        Hive.registerAdapter(FlashcardDeckAdapter());
        Hive.registerAdapter(ExamAdapter());
        Hive.registerAdapter(ExamPriorityAdapter());
      }

      // Open all boxes
      await Future.wait([
        _openBox<Task>('tasks'),
        _openBox<StudyGoal>('study_goals'),
        _openBox<Achievement>('achievements'),
        _openBox<Flashcard>('flashcards'),
        _openBox<FlashcardDeck>('flashcard_decks'),
        _openBox<Exam>('exams'),
      ]);

      _isInitialized = true;
      print('HiveService: All boxes initialized successfully');
    } catch (e) {
      print('HiveService: Error initializing Hive: $e');
      rethrow;
    }
  }

  Future<Box<T>> _openBox<T>(String boxName) async {
    if (_boxes.containsKey(boxName)) {
      return _boxes[boxName] as Box<T>;
    }

    try {
      final box = await Hive.openBox<T>(boxName);
      _boxes[boxName] = box;
      return box;
    } catch (e) {
      print('HiveService: Error opening box $boxName: $e');
      rethrow;
    }
  }

  // Safe box access methods
  Future<Box<Task>> getTasksBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<Task>('tasks');
  }

  Future<Box<StudyGoal>> getStudyGoalsBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<StudyGoal>('study_goals');
  }

  Future<Box<Achievement>> getAchievementsBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<Achievement>('achievements');
  }

  Future<Box<Flashcard>> getFlashcardsBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<Flashcard>('flashcards');
  }

  Future<Box<FlashcardDeck>> getFlashcardDecksBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<FlashcardDeck>('flashcard_decks');
  }

  Future<Box<Exam>> getExamsBox() async {
    if (!_isInitialized) await initialize();
    return _openBox<Exam>('exams');
  }

  // Synchronous access methods (use only after initialization)
  Box<Task>? getTasksBoxSync() {
    return _boxes['tasks'] as Box<Task>?;
  }

  Box<StudyGoal>? getStudyGoalsBoxSync() {
    return _boxes['study_goals'] as Box<StudyGoal>?;
  }

  Box<Achievement>? getAchievementsBoxSync() {
    return _boxes['achievements'] as Box<Achievement>?;
  }

  Box<Flashcard>? getFlashcardsBoxSync() {
    return _boxes['flashcards'] as Box<Flashcard>?;
  }

  Box<FlashcardDeck>? getFlashcardDecksBoxSync() {
    return _boxes['flashcard_decks'] as Box<FlashcardDeck>?;
  }

  Box<Exam>? getExamsBoxSync() {
    return _boxes['exams'] as Box<Exam>?;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    for (final box in _boxes.values) {
      box.close();
    }
    _boxes.clear();
    _isInitialized = false;
  }
} 