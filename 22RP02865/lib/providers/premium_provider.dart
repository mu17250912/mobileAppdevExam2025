import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  String? _premiumPlan;
  DateTime? _premiumExpiryDate;
  final AnalyticsService _analytics = AnalyticsService();
  final AdService _adService = AdService();

  bool get isPremium => _isPremium;
  String? get premiumPlan => _premiumPlan;
  DateTime? get premiumExpiryDate => _premiumExpiryDate;
  
  // Premium features
  bool get hasUnlimitedTasks => _isPremium;
  bool get hasAdvancedAnalytics => _isPremium;
  bool get hasCustomThemes => _isPremium;
  bool get hasPrioritySupport => _isPremium;
  bool get hasCloudBackup => _isPremium;
  bool get hasAdFreeExperience => _isPremium;
  bool get hasExportData => _isPremium;
  bool get hasMultipleSubjects => _isPremium;
  bool get hasStudyReminders => _isPremium;
  bool get hasProgressTracking => _isPremium;

  // Check if premium is expired
  bool get isPremiumExpired {
    if (!_isPremium || _premiumExpiryDate == null) return false;
    return DateTime.now().isAfter(_premiumExpiryDate!);
  }

  // Days remaining in premium
  int get daysRemaining {
    if (!_isPremium || _premiumExpiryDate == null) return 0;
    final remaining = _premiumExpiryDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  PremiumProvider() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('isPremium') ?? false;
    _premiumPlan = prefs.getString('premiumPlan');
    
    final expiryString = prefs.getString('premiumExpiryDate');
    if (expiryString != null) {
      _premiumExpiryDate = DateTime.parse(expiryString);
    }
    
    notifyListeners();
  }

  Future<void> upgradeToPremium({
    required String plan,
    int? durationDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    await prefs.setString('premiumPlan', plan);
    
    // Set expiry date based on plan
    DateTime expiryDate;
    switch (plan) {
      case 'monthly':
        expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case 'yearly':
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case 'lifetime':
        expiryDate = DateTime.now().add(const Duration(days: 36500)); // 100 years
        break;
      default:
        expiryDate = durationDays != null 
            ? DateTime.now().add(Duration(days: durationDays))
            : DateTime.now().add(const Duration(days: 30));
    }
    
    await prefs.setString('premiumExpiryDate', expiryDate.toIso8601String());
    
    _isPremium = true;
    _premiumPlan = plan;
    _premiumExpiryDate = expiryDate;
    
    // Track premium upgrade
    await _analytics.trackPremiumUpgrade(plan);
    
    // Reset ad counter for premium users
    await _adService.resetAdCounter();
    
    notifyListeners();
  }

  Future<void> removePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', false);
    await prefs.remove('premiumPlan');
    await prefs.remove('premiumExpiryDate');
    
    _isPremium = false;
    _premiumPlan = null;
    _premiumExpiryDate = null;
    
    // Track premium removal
    await _analytics.trackEvent('premium_removed', {
      'plan': _premiumPlan ?? 'unknown',
    });
    
    notifyListeners();
  }

  Future<void> extendPremium(int additionalDays) async {
    if (!_isPremium) return;
    
    final newExpiryDate = _premiumExpiryDate?.add(Duration(days: additionalDays)) 
        ?? DateTime.now().add(Duration(days: additionalDays));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('premiumExpiryDate', newExpiryDate.toIso8601String());
    
    _premiumExpiryDate = newExpiryDate;
    
    // Track premium extension
    await _analytics.trackEvent('premium_extended', {
      'additional_days': additionalDays,
      'new_expiry': newExpiryDate.toIso8601String(),
    });
    
    notifyListeners();
  }

  // Check premium feature access
  bool hasFeatureAccess(String feature) {
    if (!_isPremium) return false;
    
    switch (feature) {
      case 'unlimited_tasks':
        return hasUnlimitedTasks;
      case 'advanced_analytics':
        return hasAdvancedAnalytics;
      case 'custom_themes':
        return hasCustomThemes;
      case 'priority_support':
        return hasPrioritySupport;
      case 'cloud_backup':
        return hasCloudBackup;
      case 'ad_free':
        return hasAdFreeExperience;
      case 'export_data':
        return hasExportData;
      case 'multiple_subjects':
        return hasMultipleSubjects;
      case 'study_reminders':
        return hasStudyReminders;
      case 'progress_tracking':
        return hasProgressTracking;
      default:
        return false;
    }
  }

  // Get premium features list
  List<Map<String, dynamic>> getPremiumFeatures() {
    return [
      {
        'id': 'unlimited_tasks',
        'name': 'Unlimited Tasks',
        'description': 'Create unlimited study tasks and assignments',
        'icon': Icons.all_inclusive,
        'available': hasUnlimitedTasks,
      },
      {
        'id': 'advanced_analytics',
        'name': 'Advanced Analytics',
        'description': 'Detailed insights into your study patterns and progress',
        'icon': Icons.analytics,
        'available': hasAdvancedAnalytics,
      },
      {
        'id': 'custom_themes',
        'name': 'Custom Themes',
        'description': 'Personalize the app with beautiful themes',
        'icon': Icons.palette,
        'available': hasCustomThemes,
      },
      {
        'id': 'priority_support',
        'name': 'Priority Support',
        'description': 'Get faster response times for support requests',
        'icon': Icons.priority_high,
        'available': hasPrioritySupport,
      },
      {
        'id': 'cloud_backup',
        'name': 'Cloud Backup',
        'description': 'Automatic backup of all your data to the cloud',
        'icon': Icons.backup,
        'available': hasCloudBackup,
      },
      {
        'id': 'ad_free',
        'name': 'Ad-Free Experience',
        'description': 'Enjoy the app without any advertisements',
        'icon': Icons.block,
        'available': hasAdFreeExperience,
      },
      {
        'id': 'export_data',
        'name': 'Export Data',
        'description': 'Export your study data in various formats',
        'icon': Icons.file_download,
        'available': hasExportData,
      },
      {
        'id': 'multiple_subjects',
        'name': 'Multiple Subjects',
        'description': 'Organize tasks by multiple subjects and categories',
        'icon': Icons.category,
        'available': hasMultipleSubjects,
      },
      {
        'id': 'study_reminders',
        'name': 'Study Reminders',
        'description': 'Advanced reminder system with custom schedules',
        'icon': Icons.notifications_active,
        'available': hasStudyReminders,
      },
      {
        'id': 'progress_tracking',
        'name': 'Progress Tracking',
        'description': 'Track your learning progress with detailed metrics',
        'icon': Icons.trending_up,
        'available': hasProgressTracking,
      },
    ];
  }

  // Get premium status summary
  Map<String, dynamic> getPremiumStatus() {
    return {
      'isPremium': _isPremium,
      'plan': _premiumPlan,
      'expiryDate': _premiumExpiryDate?.toIso8601String(),
      'isExpired': isPremiumExpired,
      'daysRemaining': daysRemaining,
      'features': getPremiumFeatures(),
    };
  }
} 