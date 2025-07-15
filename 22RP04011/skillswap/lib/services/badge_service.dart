import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class BadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined badges
  static final List<Badge> _predefinedBadges = [
    // Session-based badges
    Badge(
      id: 'sessions_5',
      name: 'Getting Started',
      description: 'Complete 5 skill swap sessions',
      emoji: '🎯',
      type: BadgeType.session,
      requiredValue: 5,
    ),
    Badge(
      id: 'sessions_10',
      name: 'Dedicated Learner',
      description: 'Complete 10 skill swap sessions',
      emoji: '🧑‍🏫',
      type: BadgeType.session,
      requiredValue: 10,
    ),
    Badge(
      id: 'sessions_25',
      name: 'Skill Enthusiast',
      description: 'Complete 25 skill swap sessions',
      emoji: '🌟',
      type: BadgeType.session,
      requiredValue: 25,
    ),
    Badge(
      id: 'sessions_50',
      name: 'Master Collaborator',
      description: 'Complete 50 skill swap sessions',
      emoji: '👑',
      type: BadgeType.session,
      requiredValue: 50,
    ),

    // Skill-specific badges
    Badge(
      id: 'javascript_master',
      name: 'JavaScript Master',
      description: 'Achieve high rating in JavaScript',
      emoji: '⚡',
      type: BadgeType.skill,
      requiredValue: 4, // 4+ star rating
      skillId: 'javascript',
    ),
    Badge(
      id: 'python_master',
      name: 'Python Master',
      description: 'Achieve high rating in Python',
      emoji: '🐍',
      type: BadgeType.skill,
      requiredValue: 4,
      skillId: 'python',
    ),
    Badge(
      id: 'design_master',
      name: 'Design Master',
      description: 'Achieve high rating in Design',
      emoji: '🎨',
      type: BadgeType.skill,
      requiredValue: 4,
      skillId: 'design',
    ),

    // Community badges
    Badge(
      id: 'top_helper',
      name: 'Top Helper',
      description: 'Rated highly for helping others',
      emoji: '💬',
      type: BadgeType.community,
      requiredValue: 10, // 10+ positive ratings
    ),
    Badge(
      id: 'mentor',
      name: 'Mentor',
      description: 'Help 20+ users learn new skills',
      emoji: '🤝',
      type: BadgeType.community,
      requiredValue: 20,
    ),
    Badge(
      id: 'community_champion',
      name: 'Community Champion',
      description: 'Be a positive force in the community',
      emoji: '🏆',
      type: BadgeType.community,
      requiredValue: 50, // 50+ positive interactions
    ),

    // Time-based badges
    Badge(
      id: 'weekly_streak_4',
      name: 'Weekly Streak (4 weeks)',
      description: 'Log in or participate consistently for 4 weeks',
      emoji: '📅',
      type: BadgeType.time,
      requiredValue: 4,
    ),
    Badge(
      id: 'weekly_streak_8',
      name: 'Weekly Streak (8 weeks)',
      description: 'Log in or participate consistently for 8 weeks',
      emoji: '📅',
      type: BadgeType.time,
      requiredValue: 8,
    ),
    Badge(
      id: 'weekly_streak_12',
      name: 'Weekly Streak (12 weeks)',
      description: 'Log in or participate consistently for 12 weeks',
      emoji: '📅',
      type: BadgeType.time,
      requiredValue: 12,
    ),
  ];

  // Get user badges
  static Stream<List<Badge>> getUserBadges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('badges')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Badge.fromFirestore(doc);
      }).toList();
    });
  }

  // Check and award session-based badges
  static Future<void> checkSessionBadges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get user's completed sessions count
    final sessionsSnapshot = await _firestore
        .collection('sessions')
        .where('participants', arrayContains: currentUser.uid)
        .where('status', isEqualTo: 'completed')
        .get();

    final completedSessions = sessionsSnapshot.docs.length;

    // Check for session badges
    for (final badge
        in _predefinedBadges.where((b) => b.type == BadgeType.session)) {
      if (completedSessions >= badge.requiredValue) {
        await _awardBadge(badge);
      }
    }
  }

  // Check and award skill-specific badges
  static Future<void> checkSkillBadges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get user's skills with ratings
    final skillsSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('skills')
        .get();

    for (final skillDoc in skillsSnapshot.docs) {
      final skillData = skillDoc.data();
      final skillId = skillDoc.id;
      final rating = skillData['rating'] ?? 0.0;

      // Check for skill-specific badges
      for (final badge in _predefinedBadges
          .where((b) => b.type == BadgeType.skill && b.skillId == skillId)) {
        if (rating >= badge.requiredValue) {
          await _awardBadge(badge);
        }
      }
    }
  }

  // Check and award community badges
  static Future<void> checkCommunityBadges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get user's positive ratings count
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: currentUser.uid)
        .where('rating', isGreaterThanOrEqualTo: 4)
        .get();

    final positiveRatings = ratingsSnapshot.docs.length;

    // Check for community badges
    for (final badge
        in _predefinedBadges.where((b) => b.type == BadgeType.community)) {
      if (positiveRatings >= badge.requiredValue) {
        await _awardBadge(badge);
      }
    }
  }

  // Check and award time-based badges
  static Future<void> checkTimeBadges() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get user's activity log
    final activitySnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    // Calculate weekly streaks
    final activities = activitySnapshot.docs.map((doc) {
      return (doc.data()['timestamp'] as Timestamp).toDate();
    }).toList();

    final weeklyStreak = _calculateWeeklyStreak(activities);

    // Check for time-based badges
    for (final badge
        in _predefinedBadges.where((b) => b.type == BadgeType.time)) {
      if (weeklyStreak >= badge.requiredValue) {
        await _awardBadge(badge);
      }
    }
  }

  // Calculate weekly streak from activity dates
  static int _calculateWeeklyStreak(List<DateTime> activities) {
    if (activities.isEmpty) return 0;

    final now = DateTime.now();
    final weeks = <int>{};

    for (final activity in activities) {
      final weekStart = DateTime(activity.year, activity.month, activity.day)
              .difference(DateTime(2020, 1, 1))
              .inDays ~/
          7;
      weeks.add(weekStart);
    }

    // Count consecutive weeks
    int streak = 0;
    final currentWeek = DateTime(now.year, now.month, now.day)
            .difference(DateTime(2020, 1, 1))
            .inDays ~/
        7;

    for (int i = 0; i <= 52; i++) {
      // Check up to 1 year
      final weekToCheck = currentWeek - i;
      if (weeks.contains(weekToCheck)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // Award badge to user
  static Future<void> _awardBadge(Badge badge) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if badge is already awarded
    final existingBadge = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('badges')
        .doc(badge.id)
        .get();

    if (existingBadge.exists) return; // Already awarded

    // Award the badge
    final awardedBadge = badge.copyWith(
      earnedAt: DateTime.now(),
      isEarned: true,
    );

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('badges')
        .doc(badge.id)
        .set(awardedBadge.toFirestore());

    // Send notification
    await _sendBadgeNotification(awardedBadge);
  }

  // Send badge notification
  static Future<void> _sendBadgeNotification(Badge badge) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('notifications').add({
      'userId': currentUser.uid,
      'title': '🎉 New Badge Earned!',
      'body': 'You earned the ${badge.emoji} ${badge.name} badge!',
      'type': 'badge',
      'isRead': false,
      'timestamp': Timestamp.now(),
      'data': {
        'badgeId': badge.id,
        'badgeName': badge.name,
        'badgeEmoji': badge.emoji,
      },
    });
  }

  // Get badge statistics
  static Future<Map<String, dynamic>> getBadgeStatistics() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    final badgesSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('badges')
        .get();

    final earnedBadges = badgesSnapshot.docs.length;
    final totalBadges = _predefinedBadges.length;
    final progress = (earnedBadges / totalBadges * 100).round();

    // Count badges by type
    final badgesByType = <BadgeType, int>{};
    for (final doc in badgesSnapshot.docs) {
      final badge = Badge.fromFirestore(doc);
      badgesByType[badge.type] = (badgesByType[badge.type] ?? 0) + 1;
    }

    return {
      'earnedBadges': earnedBadges,
      'totalBadges': totalBadges,
      'progress': progress,
      'badgesByType': badgesByType,
    };
  }

  // Get recent badges
  static Future<List<Badge>> getRecentBadges({int limit = 5}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final badgesSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('badges')
        .orderBy('earnedAt', descending: true)
        .limit(limit)
        .get();

    return badgesSnapshot.docs.map((doc) {
      return Badge.fromFirestore(doc);
    }).toList();
  }

  // Check all badges (called periodically)
  static Future<void> checkAllBadges() async {
    await checkSessionBadges();
    await checkSkillBadges();
    await checkCommunityBadges();
    await checkTimeBadges();
  }

  // Log user activity for time-based badges
  static Future<void> logActivity(String activityType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('activity')
        .add({
      'type': activityType,
      'timestamp': Timestamp.now(),
    });
  }
}
