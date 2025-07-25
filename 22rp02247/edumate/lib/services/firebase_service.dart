import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Authentication Methods
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap()
            ..['isPremium'] = 'false');

      // Log analytics event
      await _analytics.logEvent(name: 'user_registered');

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .update({'lastLoginAt': Timestamp.fromDate(DateTime.now())});

      // Log analytics event
      await _analytics.logEvent(name: 'user_login');

      return credential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _analytics.logEvent(name: 'user_logout');
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User Profile Methods
  static Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  static Future<void> updateUserPremiumStatus(String uid, bool isPremium) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'isPremium': isPremium ? 'true' : 'false'});
      
      await _analytics.logEvent(
        name: 'premium_upgrade',
        parameters: {'is_premium': isPremium ? 'true' : 'false'},
      );
    } catch (e) {
      throw Exception('Failed to update premium status: $e');
    }
  }

  // Notes Methods
  static Future<void> addNote(NoteModel note) async {
    try {
      await _firestore
          .collection('notes')
          .doc(note.id)
          .set(note.toMap());
      
      await _analytics.logEvent(name: 'note_created');
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  static Future<void> updateNote(NoteModel note) async {
    try {
      await _firestore
          .collection('notes')
          .doc(note.id)
          .update(note.toMap());
      
      await _analytics.logEvent(name: 'note_updated');
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  static Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
      await _analytics.logEvent(name: 'note_deleted');
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  static Stream<List<NoteModel>> getUserNotes(String userId) {
    print('FirebaseService: Getting notes for user: $userId');
    
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('FirebaseService: Got ${snapshot.docs.length} notes from Firestore');
          final notes = snapshot.docs.map((doc) {
            print('FirebaseService: Processing note: ${doc.data()}');
            return NoteModel.fromMap(doc.data());
          }).toList();
          
          // Sort by updatedAt descending
          notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          print('FirebaseService: Returning ${notes.length} sorted notes');
          return notes;
        });
  }

  // Flashcards Methods
  static Future<void> addFlashcard(FlashcardModel flashcard) async {
    try {
      await _firestore
          .collection('flashcards')
          .doc(flashcard.id)
          .set(flashcard.toMap());
      
      await _analytics.logEvent(name: 'flashcard_created');
    } catch (e) {
      throw Exception('Failed to add flashcard: $e');
    }
  }

  static Future<void> updateFlashcard(FlashcardModel flashcard) async {
    try {
      await _firestore
          .collection('flashcards')
          .doc(flashcard.id)
          .update(flashcard.toMap());
      
      await _analytics.logEvent(name: 'flashcard_updated');
    } catch (e) {
      throw Exception('Failed to update flashcard: $e');
    }
  }

  static Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _firestore.collection('flashcards').doc(flashcardId).delete();
      await _analytics.logEvent(name: 'flashcard_deleted');
    } catch (e) {
      throw Exception('Failed to delete flashcard: $e');
    }
  }

  static Stream<List<FlashcardModel>> getUserFlashcards(String userId) {
    print('DEBUG: FirebaseService - Getting flashcards for user: $userId');
    
    return _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: FirebaseService - Got ${snapshot.docs.length} flashcards from Firestore for user: $userId');
          
          final flashcards = snapshot.docs.map((doc) {
            print('DEBUG: FirebaseService - Processing flashcard: ${doc.data()}');
            return FlashcardModel.fromMap(doc.data());
          }).toList();
          
          // Sort by createdAt descending
          flashcards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('DEBUG: FirebaseService - Returning ${flashcards.length} sorted flashcards for user: $userId');
          return flashcards;
        });
  }

  // Quiz Methods
  static Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    try {
      print('DEBUG: Saving quiz attempt for user: ${attempt.userId}, attempt id: ${attempt.id}');
      await _firestore
          .collection('quiz_attempts')
          .doc(attempt.id)
          .set(attempt.toMap());
      
      await _analytics.logEvent(
        name: 'quiz_completed',
        parameters: {
          'score': attempt.score,
          'total_questions': attempt.totalQuestions,
          'percentage': attempt.percentage,
        },
      );
    } catch (e) {
      throw Exception('Failed to save quiz attempt: $e');
    }
  }

  static Stream<List<QuizAttempt>> getUserQuizAttempts(String userId) {
    return _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuizAttempt.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt)));
  }

  // Analytics Methods
  static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Analytics errors shouldn't break the app
      print('Analytics error: $e');
    }
  }

  static Future<void> setUserProperties({
    required String userId,
    required bool isPremium,
  }) async {
    try {
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'is_premium', value: isPremium ? 'true' : 'false');
    } catch (e) {
      print('Failed to set user properties: $e');
    }
  }

  // Test Methods
  static Future<bool> testFirebaseConnection() async {
    try {
      // Test if we can read from Firestore
      final testDoc = await _firestore.collection('test').doc('connection_test').get();
      
      // Test if we can write to Firestore
      await _firestore.collection('test').doc('connection_test').set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> testNotesRetrieval(String userId) async {
    try {
      print('Testing notes retrieval for user: $userId');
      
      // Test simple query without orderBy
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('Found ${snapshot.docs.length} notes for user $userId');
      
      for (var doc in snapshot.docs) {
        print('Note: ${doc.data()}');
      }
    } catch (e) {
      print('Error testing notes retrieval: $e');
    }
  }

  static Future<void> createTestNote(String userId) async {
    try {
      print('Creating test note for user: $userId');
      
      final testNoteId = 'test_note_${DateTime.now().millisecondsSinceEpoch}';
      final testNote = {
        'id': testNoteId,
        'userId': userId,
        'title': 'Test Note ${DateTime.now().toString()}',
        'content': 'This is a test note to verify the app is working properly.',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'tags': ['test', 'debug'],
      };
      
      await _firestore
          .collection('notes')
          .doc(testNoteId)
          .set(testNote);
      
      print('Test note created successfully: $testNote');
    } catch (e) {
      print('Error creating test note: $e');
    }
  }

  // Error Handling
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
} 