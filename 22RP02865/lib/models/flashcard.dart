import 'package:hive/hive.dart';
import '../services/hive_service.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 5)
class Flashcard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  String answer;

  @HiveField(3)
  String subject;

  @HiveField(4)
  String? hint;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime lastReviewed;

  @HiveField(7)
  int reviewCount;

  @HiveField(8)
  double confidenceLevel; // 0.0 to 1.0

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  bool isFavorite;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.subject,
    this.hint,
    DateTime? createdAt,
    DateTime? lastReviewed,
    this.reviewCount = 0,
    this.confidenceLevel = 0.5,
    this.tags = const [],
    this.isFavorite = false,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastReviewed = lastReviewed ?? DateTime.now();

  // Calculate next review date based on confidence level
  DateTime get nextReviewDate {
    final daysToAdd = _calculateDaysToAdd();
    return lastReviewed.add(Duration(days: daysToAdd));
  }

  // Spaced repetition algorithm
  int _calculateDaysToAdd() {
    if (confidenceLevel < 0.3) return 1; // Review tomorrow
    if (confidenceLevel < 0.5) return 3; // Review in 3 days
    if (confidenceLevel < 0.7) return 7; // Review in a week
    if (confidenceLevel < 0.9) return 14; // Review in 2 weeks
    return 30; // Review in a month
  }

  // Update confidence level based on user performance
  void updateConfidence(bool wasCorrect) {
    if (wasCorrect) {
      confidenceLevel = (confidenceLevel + 0.1).clamp(0.0, 1.0);
    } else {
      confidenceLevel = (confidenceLevel - 0.2).clamp(0.0, 1.0);
    }
    reviewCount++;
    lastReviewed = DateTime.now();
  }

  // Check if card is due for review
  bool get isDueForReview {
    return DateTime.now().isAfter(nextReviewDate);
  }

  // Get difficulty level based on confidence
  String get difficultyLevel {
    if (confidenceLevel < 0.3) return 'Hard';
    if (confidenceLevel < 0.7) return 'Medium';
    return 'Easy';
  }

  // Get color based on difficulty
  int get difficultyColor {
    if (confidenceLevel < 0.3) return 0xFFFF6B6B; // Red
    if (confidenceLevel < 0.7) return 0xFFFFA726; // Orange
    return 0xFF66BB6A; // Green
  }
}

@HiveType(typeId: 6)
class FlashcardDeck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String subject;

  @HiveField(4)
  List<String> flashcardIds;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime lastStudied;

  @HiveField(7)
  int totalCards;

  @HiveField(8)
  int masteredCards;

  @HiveField(9)
  bool isPublic;

  @HiveField(10)
  String? createdBy;

  FlashcardDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    this.flashcardIds = const [],
    DateTime? createdAt,
    DateTime? lastStudied,
    this.totalCards = 0,
    this.masteredCards = 0,
    this.isPublic = false,
    this.createdBy,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastStudied = lastStudied ?? DateTime.now();

  double get masteryPercentage {
    if (totalCards == 0) return 0.0;
    return (masteredCards / totalCards) * 100;
  }

  int get dueCards {
    // This would be calculated based on individual flashcard review dates
    return flashcardIds.length; // Simplified for now
  }

  void updateStats(int total, int mastered) {
    totalCards = total;
    masteredCards = mastered;
    lastStudied = DateTime.now();
  }
}

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  // Create a new flashcard
  Future<Flashcard> createFlashcard({
    required String question,
    required String answer,
    required String subject,
    String? hint,
    List<String> tags = const [],
  }) async {
    final flashcard = Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: answer,
      subject: subject,
      hint: hint,
      tags: tags,
    );

    final box = await HiveService().getFlashcardsBox();
    await box.put(flashcard.id, flashcard);
    return flashcard;
  }

  // Create a new deck
  Future<FlashcardDeck> createDeck({
    required String name,
    required String description,
    required String subject,
    bool isPublic = false,
    String? createdBy,
  }) async {
    final deck = FlashcardDeck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      subject: subject,
      isPublic: isPublic,
      createdBy: createdBy,
    );

    final box = await HiveService().getFlashcardDecksBox();
    await box.put(deck.id, deck);
    return deck;
  }

  // Get all flashcards
  Future<List<Flashcard>> getAllFlashcards() async {
    final box = await HiveService().getFlashcardsBox();
    return box.values.toList();
  }

  // Get flashcards by subject
  Future<List<Flashcard>> getFlashcardsBySubject(String subject) async {
    final box = await HiveService().getFlashcardsBox();
    return box.values.where((card) => card.subject == subject).toList();
  }

  // Get flashcards due for review
  Future<List<Flashcard>> getDueFlashcards() async {
    final box = await HiveService().getFlashcardsBox();
    return box.values.where((card) => card.isDueForReview).toList();
  }

  // Get all decks
  Future<List<FlashcardDeck>> getAllDecks() async {
    final box = await HiveService().getFlashcardDecksBox();
    return box.values.toList();
  }

  // Get public decks
  Future<List<FlashcardDeck>> getPublicDecks() async {
    final box = await HiveService().getFlashcardDecksBox();
    return box.values.where((deck) => deck.isPublic).toList();
  }

  // Add flashcard to deck
  Future<void> addFlashcardToDeck(String deckId, String flashcardId) async {
    final deckBox = await HiveService().getFlashcardDecksBox();
    final deck = deckBox.get(deckId);
    if (deck != null) {
      deck.flashcardIds.add(flashcardId);
      deck.totalCards = deck.flashcardIds.length;
      await deckBox.put(deckId, deck);
    }
  }

  // Remove flashcard from deck
  Future<void> removeFlashcardFromDeck(String deckId, String flashcardId) async {
    final deckBox = await HiveService().getFlashcardDecksBox();
    final deck = deckBox.get(deckId);
    if (deck != null) {
      deck.flashcardIds.remove(flashcardId);
      deck.totalCards = deck.flashcardIds.length;
      await deckBox.put(deckId, deck);
    }
  }

  // Update flashcard confidence
  Future<void> updateFlashcardConfidence(String flashcardId, bool wasCorrect) async {
    final box = await HiveService().getFlashcardsBox();
    final flashcard = box.get(flashcardId);
    if (flashcard != null) {
      flashcard.updateConfidence(wasCorrect);
      await box.put(flashcardId, flashcard);
    }
  }

  // Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    final box = await HiveService().getFlashcardsBox();
    await box.delete(flashcardId);
  }

  // Delete deck
  Future<void> deleteDeck(String deckId) async {
    final box = await HiveService().getFlashcardDecksBox();
    await box.delete(deckId);
  }

  // Search flashcards
  Future<List<Flashcard>> searchFlashcards(String query) async {
    final box = await HiveService().getFlashcardsBox();
    final queryLower = query.toLowerCase();
    return box.values.where((card) =>
      card.question.toLowerCase().contains(queryLower) ||
      card.answer.toLowerCase().contains(queryLower) ||
      card.subject.toLowerCase().contains(queryLower) ||
      card.tags.any((tag) => tag.toLowerCase().contains(queryLower))
    ).toList();
  }

  // Get study statistics
  Future<Map<String, dynamic>> getStudyStats() async {
    final box = await HiveService().getFlashcardsBox();
    final cards = box.values.toList();
    
    final totalCards = cards.length;
    final masteredCards = cards.where((card) => card.confidenceLevel >= 0.8).length;
    final dueCards = cards.where((card) => card.isDueForReview).length;
    final totalReviews = cards.fold(0, (sum, card) => sum + card.reviewCount);
    
    return {
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'dueCards': dueCards,
      'totalReviews': totalReviews,
      'masteryPercentage': totalCards > 0 ? (masteredCards / totalCards) * 100 : 0,
    };
  }
} 