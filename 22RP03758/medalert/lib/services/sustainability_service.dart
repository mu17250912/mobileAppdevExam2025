import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class SustainabilityService {
  static final SustainabilityService _instance = SustainabilityService._internal();
  factory SustainabilityService() => _instance;
  SustainabilityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Stream controllers
  final StreamController<AppUpdateInfo> _updateController = 
      StreamController<AppUpdateInfo>.broadcast();
  final StreamController<List<RetentionInsight>> _insightsController = 
      StreamController<List<RetentionInsight>>.broadcast();
  final StreamController<ReferralInfo> _referralController = 
      StreamController<ReferralInfo>.broadcast();

  // Getters
  Stream<AppUpdateInfo> get updateStream => _updateController.stream;
  Stream<List<RetentionInsight>> get insightsStream => _insightsController.stream;
  Stream<ReferralInfo> get referralStream => _referralController.stream;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Check for app updates
      await _checkForUpdates();
      
      // Generate retention insights
      await _generateRetentionInsights();
      
      // Initialize referral system
      await _initializeReferralSystem();
    } catch (e) {
      print('Error initializing sustainability service: $e');
    }
  }

  // Check for app updates
  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // Get update info from Firestore
      final updateDoc = await _firestore
          .collection('app_updates')
          .doc('latest')
          .get();

      if (updateDoc.exists) {
        final data = updateDoc.data()!;
        final latestVersion = data['version'] as String;
        final latestBuild = data['build_number'] as int;
        final updateType = data['update_type'] as String; // critical, important, optional
        final updateNotes = data['update_notes'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;
        final releaseDate = (data['release_date'] as Timestamp).toDate();

        final appUpdateInfo = AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          currentBuild: int.parse(buildNumber),
          latestBuild: latestBuild,
          updateType: updateType,
          updateNotes: updateNotes,
          forceUpdate: forceUpdate,
          releaseDate: releaseDate,
          hasUpdate: _compareVersions(latestVersion, currentVersion) > 0,
        );

        _updateController.add(appUpdateInfo);
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  // Compare version strings
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }

    if (v1Parts.length > v2Parts.length) return 1;
    if (v1Parts.length < v2Parts.length) return -1;
    return 0;
  }

  // Generate retention insights
  Future<void> _generateRetentionInsights() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final insights = <RetentionInsight>[];

      // Get user's medication adherence data (simplified query to avoid index issues)
      final adherenceQuery = await _firestore
          .collection('medication_logs')
          .where('userId', isEqualTo: user.uid)
          .limit(30)
          .get();

      if (adherenceQuery.docs.isNotEmpty) {
        // Calculate adherence streak
        int currentStreak = 0;
        int maxStreak = 0;
        DateTime? lastTakenDate;

        for (final doc in adherenceQuery.docs) {
          final data = doc.data();
          final taken = data['taken'] as bool;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

          if (taken) {
            if (lastTakenDate == null || 
                date.difference(lastTakenDate).inDays == 1) {
              currentStreak++;
              maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
            } else {
              currentStreak = 1;
            }
            lastTakenDate = date;
          } else {
            currentStreak = 0;
          }
        }

        // Add streak insight
        if (currentStreak > 0) {
          insights.add(RetentionInsight(
            type: RetentionInsightType.streak,
            title: 'Great Job!',
            message: 'You\'ve maintained a $currentStreak-day streak! Keep it up!',
            priority: InsightPriority.high,
            actionType: InsightActionType.celebrate,
          ));
        }

        // Add max streak insight
        if (maxStreak > currentStreak && maxStreak > 7) {
          insights.add(RetentionInsight(
            type: RetentionInsightType.streak,
            title: 'Personal Best!',
            message: 'Your longest streak was $maxStreak days. Try to beat it!',
            priority: InsightPriority.medium,
            actionType: InsightActionType.motivate,
          ));
        }
      }

      // Get medication count
      final medicationQuery = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: user.uid)
          .get();

      final medicationCount = medicationQuery.docs.length;

      // Add medication management insight
      if (medicationCount == 0) {
        insights.add(RetentionInsight(
          type: RetentionInsightType.medication,
          title: 'Get Started',
          message: 'Add your first medication to start tracking your health journey!',
          priority: InsightPriority.high,
          actionType: InsightActionType.addMedication,
        ));
      } else if (medicationCount > 5) {
        insights.add(RetentionInsight(
          type: RetentionInsightType.medication,
          title: 'Medication Management',
          message: 'You\'re managing $medicationCount medications. Consider setting up caregiver support.',
          priority: InsightPriority.medium,
          actionType: InsightActionType.caregiverSetup,
        ));
      }

      // Get user's app usage patterns (simplified query to avoid index issues)
      final usageQuery = await _firestore
          .collection('app_usage')
          .where('userId', isEqualTo: user.uid)
          .limit(7)
          .get();

      if (usageQuery.docs.length < 3) {
        insights.add(RetentionInsight(
          type: RetentionInsightType.engagement,
          title: 'Stay Connected',
          message: 'Regular app usage helps you stay on track with your medications.',
          priority: InsightPriority.medium,
          actionType: InsightActionType.reminder,
        ));
      }

      // Get user's notification preferences
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final notificationsEnabled = userData['notificationsEnabled'] ?? true;

        if (!notificationsEnabled) {
          insights.add(RetentionInsight(
            type: RetentionInsightType.notification,
            title: 'Stay Updated',
            message: 'Enable notifications to never miss your medication reminders.',
            priority: InsightPriority.high,
            actionType: InsightActionType.enableNotifications,
          ));
        }
      }

      _insightsController.add(insights);
    } catch (e) {
      print('Error generating retention insights: $e');
    }
  }

  // Initialize referral system
  Future<void> _initializeReferralSystem() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user has a referral code
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final referralCode = userData['referralCode'] as String?;

        if (referralCode == null) {
          // Generate new referral code
          final newReferralCode = _generateReferralCode();
          await _firestore.collection('users').doc(user.uid).update({
            'referralCode': newReferralCode,
            'referralCodeGeneratedAt': FieldValue.serverTimestamp(),
          });

          final referralInfo = ReferralInfo(
            code: newReferralCode,
            referrals: 0,
            rewards: 0,
            maxRewards: 10,
          );

          _referralController.add(referralInfo);
        } else {
          // Get existing referral stats
          final referralStats = await _getReferralStats(user.uid);
          _referralController.add(referralStats);
        }
      }
    } catch (e) {
      print('Error initializing referral system: $e');
    }
  }

  // Generate referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    
    for (int i = 0; i < 6; i++) {
      code.write(chars[random % chars.length]);
    }
    
    return code.toString();
  }

  // Get referral stats
  Future<ReferralInfo> _getReferralStats(String userId) async {
    try {
      final referralsQuery = await _firestore
          .collection('users')
          .where('referredBy', isEqualTo: userId)
          .get();

      final referrals = referralsQuery.docs.length;
      final rewards = (referrals * 0.5).floor(); // 0.5 reward per referral

      return ReferralInfo(
        code: '', // Will be filled by caller
        referrals: referrals,
        rewards: rewards,
        maxRewards: 10,
      );
    } catch (e) {
      print('Error getting referral stats: $e');
      return ReferralInfo(
        code: '',
        referrals: 0,
        rewards: 0,
        maxRewards: 10,
      );
    }
  }

  // Track app usage
  Future<void> trackAppUsage({
    required String screenName,
    required int durationSeconds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final deviceInfo = await _getDeviceInfo();

      await _firestore.collection('app_usage').add({
        'userId': user.uid,
        'screenName': screenName,
        'durationSeconds': durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
      });
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Get device info
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'version': androidInfo.version.release,
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    return {};
  }

  // Share app referral
  Future<void> shareReferral() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final referralCode = userData['referralCode'] as String?;

        if (referralCode != null) {
          final shareText = '''
Join me on MedAlert - the smart medication management app!

Use my referral code: $referralCode

Download now and get started with better medication management:
[App Store/Play Store Link]

Track your medications, get smart reminders, and stay healthy with MedAlert!
          ''';

          await Share.share(shareText, subject: 'Join MedAlert with my referral code!');
        }
      }
    } catch (e) {
      print('Error sharing referral: $e');
    }
  }

  // Apply referral code
  Future<bool> applyReferralCode(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if code exists
      final referralQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .get();

      if (referralQuery.docs.isEmpty) {
        return false; // Invalid code
      }

      final referrerDoc = referralQuery.docs.first;
      final referrerId = referrerDoc.id;

      if (referrerId == user.uid) {
        return false; // Can't refer yourself
      }

      // Check if user already used a referral code
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['referredBy'] != null) {
          return false; // Already used a referral code
        }
      }

      // Apply referral
      await _firestore.collection('users').doc(user.uid).update({
        'referredBy': referrerId,
        'referralAppliedAt': FieldValue.serverTimestamp(),
      });

      // Update referrer's stats
      await _firestore.collection('users').doc(referrerId).update({
        'referralCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }

  // Get update roadmap
  Future<List<UpdateRoadmapItem>> getUpdateRoadmap() async {
    try {
      final roadmapQuery = await _firestore
          .collection('update_roadmap')
          .orderBy('plannedDate')
          .get();

      return roadmapQuery.docs.map((doc) {
        final data = doc.data();
        return UpdateRoadmapItem(
          version: data['version'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          features: List<String>.from(data['features'] ?? []),
          plannedDate: (data['plannedDate'] as Timestamp).toDate(),
          status: data['status'] as String, // planned, in_progress, completed
        );
      }).toList();
    } catch (e) {
      print('Error getting update roadmap: $e');
      return [];
    }
  }

  // Submit feedback
  Future<bool> submitFeedback({
    required String type,
    required String message,
    String? category,
    int? rating,
  }) async {
    try {
      final user = _auth.currentUser;
      final deviceInfo = await _getDeviceInfo();

      await _firestore.collection('feedback').add({
        'userId': user?.uid,
        'type': type, // bug, feature, general
        'message': message,
        'category': category,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'status': 'pending', // pending, reviewed, resolved
      });

      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Get referral code for current user
  Future<String> getReferralCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '';

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['referralCode'] ?? '';
      }

      // Generate new referral code if none exists
      final referralCode = _generateReferralCode();
      await _firestore.collection('users').doc(user.uid).update({
        'referralCode': referralCode,
      });

      return referralCode;
    } catch (e) {
      print('Error getting referral code: $e');
      return '';
    }
  }

  // Get referral count for current user
  Future<int> getReferralCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['referralCount'] ?? 0;
      }

      return 0;
    } catch (e) {
      print('Error getting referral count: $e');
      return 0;
    }
  }

  // Get referral rewards for current user
  Future<List<String>> getReferralRewards() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final referralCount = await getReferralCount();
      final rewards = <String>[];

      // Define reward milestones
      if (referralCount >= 1) {
        rewards.add('1 Month Premium Free');
      }
      if (referralCount >= 3) {
        rewards.add('3 Months Premium Free');
      }
      if (referralCount >= 5) {
        rewards.add('Lifetime Premium Access');
      }
      if (referralCount >= 10) {
        rewards.add('Family Plan Upgrade');
      }

      return rewards;
    } catch (e) {
      print('Error getting referral rewards: $e');
      return [];
    }
  }

  // Track referral share
  Future<void> trackReferralShare() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('referral_shares').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
    } catch (e) {
      print('Error tracking referral share: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _updateController.close();
    _insightsController.close();
    _referralController.close();
  }
}

// Data models
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuild;
  final int latestBuild;
  final String updateType;
  final String updateNotes;
  final bool forceUpdate;
  final DateTime releaseDate;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuild,
    required this.latestBuild,
    required this.updateType,
    required this.updateNotes,
    required this.forceUpdate,
    required this.releaseDate,
    required this.hasUpdate,
  });
}

class RetentionInsight {
  final RetentionInsightType type;
  final String title;
  final String message;
  final InsightPriority priority;
  final InsightActionType actionType;

  RetentionInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.actionType,
  });
}

enum RetentionInsightType {
  streak,
  medication,
  engagement,
  notification,
}

enum InsightPriority {
  low,
  medium,
  high,
}

enum InsightActionType {
  celebrate,
  motivate,
  addMedication,
  caregiverSetup,
  reminder,
  enableNotifications,
}

class ReferralInfo {
  final String code;
  final int referrals;
  final int rewards;
  final int maxRewards;

  ReferralInfo({
    required this.code,
    required this.referrals,
    required this.rewards,
    required this.maxRewards,
  });
}

class UpdateRoadmapItem {
  final String version;
  final String title;
  final String description;
  final List<String> features;
  final DateTime plannedDate;
  final String status;

  UpdateRoadmapItem({
    required this.version,
    required this.title,
    required this.description,
    required this.features,
    required this.plannedDate,
    required this.status,
  });
} 