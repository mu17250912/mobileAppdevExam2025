import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class GamificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Achievement types
  static const Map<String, Map<String, dynamic>> achievements = {
    'first_expense': {
      'title': 'First Step',
      'description': 'Added your first expense',
      'icon': '💰',
      'points': 10,
    },
    'streak_7': {
      'title': 'Week Warrior',
      'description': 'Used the app for 7 consecutive days',
      'icon': '🔥',
      'points': 50,
    },
    'streak_30': {
      'title': 'Monthly Master',
      'description': 'Used the app for 30 consecutive days',
      'icon': '👑',
      'points': 200,
    },
    'budget_saver': {
      'title': 'Budget Saver',
      'description': 'Stayed under budget for a month',
      'icon': '🎯',
      'points': 100,
    },
    'expense_tracker': {
      'title': 'Expense Tracker',
      'description': 'Tracked 50 expenses',
      'icon': '📊',
      'points': 75,
    },
    'category_expert': {
      'title': 'Category Expert',
      'description': 'Used all expense categories',
      'icon': '🏷️',
      'points': 60,
    },
    'savings_goal': {
      'title': 'Savings Champion',
      'description': 'Saved more than 20% of your budget',
      'icon': '💎',
      'points': 150,
    },
    'early_bird': {
      'title': 'Early Bird',
      'description': 'Logged expenses before 9 AM',
      'icon': '🌅',
      'points': 25,
    },
  };

  // Check and award achievements
  static Future<List<String>> checkAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final List<String> newAchievements = [];
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final earnedAchievements = List<String>.from(userData['achievements'] ?? []);

    // Check first expense achievement
    if (!earnedAchievements.contains('first_expense')) {
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .limit(1)
          .get();
      
      if (expensesQuery.docs.isNotEmpty) {
        earnedAchievements.add('first_expense');
        newAchievements.add('first_expense');
      }
    }

    // Check streak achievements
    final currentStreak = await getCurrentStreak();
    if (currentStreak >= 7 && !earnedAchievements.contains('streak_7')) {
      earnedAchievements.add('streak_7');
      newAchievements.add('streak_7');
    }
    if (currentStreak >= 30 && !earnedAchievements.contains('streak_30')) {
      earnedAchievements.add('streak_30');
      newAchievements.add('streak_30');
    }

    // Check expense count achievement
    if (!earnedAchievements.contains('expense_tracker')) {
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .get();
      
      if (expensesQuery.docs.length >= 50) {
        earnedAchievements.add('expense_tracker');
        newAchievements.add('expense_tracker');
      }
    }

    // Check category expert achievement
    if (!earnedAchievements.contains('category_expert')) {
      final expensesQuery = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .get();
      
      final categories = expensesQuery.docs.map((doc) => doc['category'] as String).toSet();
      if (categories.length >= 8) { // Assuming 8 main categories
        earnedAchievements.add('category_expert');
        newAchievements.add('category_expert');
      }
    }

    // Check early bird achievement
    if (!earnedAchievements.contains('early_bird')) {
      final todayExpenses = await _firestore
          .collection('expenses')
          .doc(user.uid)
          .collection('user_expenses')
          .where('date', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)))
          .get();
      
      for (var doc in todayExpenses.docs) {
        final timestamp = doc['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final hour = timestamp.toDate().hour;
          if (hour < 9) {
            earnedAchievements.add('early_bird');
            newAchievements.add('early_bird');
            break;
          }
        }
      }
    }

    // Update user achievements in Firestore
    if (newAchievements.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update({
        'achievements': earnedAchievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Show notification for new achievements
      for (final achievementId in newAchievements) {
        final achievement = achievements[achievementId];
        if (achievement != null) {
          await NotificationHelper.showNotification(
            title: '🏆 Achievement Unlocked!',
            body: '${achievement['title']}: ${achievement['description']}',
          );
        }
      }
    }

    return newAchievements;
  }

  // Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak') ?? 0;
  }

  // Get user level based on total points
  static Future<Map<String, dynamic>> getUserLevel() async {
    final user = _auth.currentUser;
    if (user == null) return {'level': 1, 'points': 0, 'nextLevel': 100};

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final earnedAchievements = List<String>.from(userData['achievements'] ?? []);

    int totalPoints = 0;
    for (final achievementId in earnedAchievements) {
      final achievement = achievements[achievementId];
      if (achievement != null) {
        totalPoints += achievement['points'] as int;
      }
    }

    final level = (totalPoints / 100).floor() + 1;
    final nextLevelPoints = level * 100;

    return {
      'level': level,
      'points': totalPoints,
      'nextLevel': nextLevelPoints,
      'progress': (totalPoints % 100) / 100,
    };
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final expensesQuery = await _firestore
        .collection('expenses')
        .doc(user.uid)
        .collection('user_expenses')
        .get();

    final budgetsQuery = await _firestore
        .collection('budgets')
        .doc(user.uid)
        .collection('user_budgets')
        .get();

    final totalExpenses = expensesQuery.docs.length;
    final totalBudgets = budgetsQuery.docs.length;
    final categories = expensesQuery.docs.map((doc) => doc['category'] as String).toSet().length;

    return {
      'totalExpenses': totalExpenses,
      'totalBudgets': totalBudgets,
      'categoriesUsed': categories,
      'streak': await getCurrentStreak(),
    };
  }

  // Get leaderboard data (mock data for now)
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    // In a real app, this would fetch from Firestore
    return [
      {'name': 'John Doe', 'level': 15, 'points': 1450, 'rank': 1},
      {'name': 'Jane Smith', 'level': 12, 'points': 1180, 'rank': 2},
      {'name': 'Mike Johnson', 'level': 10, 'points': 980, 'rank': 3},
      {'name': 'Sarah Wilson', 'level': 8, 'points': 750, 'rank': 4},
      {'name': 'David Brown', 'level': 6, 'points': 520, 'rank': 5},
    ];
  }

  // Get daily challenges
  static Future<List<Map<String, dynamic>>> getDailyChallenges() async {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    
    return [
      {
        'id': 'daily_expense',
        'title': 'Track Today\'s Expenses',
        'description': 'Log at least 3 expenses today',
        'reward': 20,
        'progress': 0,
        'maxProgress': 3,
        'completed': false,
      },
      {
        'id': 'budget_check',
        'title': 'Budget Review',
        'description': 'Check your budget status',
        'reward': 15,
        'progress': 0,
        'maxProgress': 1,
        'completed': false,
      },
      {
        'id': 'early_log',
        'title': 'Early Bird',
        'description': 'Log an expense before 10 AM',
        'reward': 25,
        'progress': 0,
        'maxProgress': 1,
        'completed': false,
      },
    ];
  }

  // Update challenge progress
  static Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'challenge_${challengeId}_${DateTime.now().day}';
    final currentProgress = prefs.getInt(key) ?? 0;
    
    await prefs.setInt(key, currentProgress + progress);
  }

  // Get motivational messages
  static List<String> getMotivationalMessages() {
    return [
      "Every expense tracked is a step toward financial freedom! 💪",
      "You're building better financial habits one day at a time! 🌟",
      "Small savings today lead to big dreams tomorrow! ✨",
      "Your future self will thank you for tracking expenses today! 🎯",
      "Consistency is the key to financial success! 🔑",
      "You're in control of your financial destiny! 💎",
      "Every budget you stick to is a victory! 🏆",
      "Smart spending today, secure future tomorrow! 🚀",
    ];
  }

  // Get random motivational message
  static String getRandomMotivationalMessage() {
    final messages = getMotivationalMessages();
    final random = DateTime.now().millisecond % messages.length;
    return messages[random];
  }
} 